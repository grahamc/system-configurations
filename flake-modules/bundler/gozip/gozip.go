package gozip

import (
	"archive/zip"
	"bytes"
	"compress/flate"
	"crypto/sha256"
	"errors"
	"io"
	"io/fs"
	"io/ioutil"
	"math/rand"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// IsZip checks to see if path is already a zip file
func IsZip(path string) bool {
	r, err := zip.OpenReader(path)
	if err == nil {
		r.Close()
		return true
	}
	return false
}

// Zip takes all the files (dirs) and zips them into path
func Zip(destinationPath string, filesToZip []string) (err error) {
	if IsZip(destinationPath) {
		return errors.New(destinationPath + " is already a zip file")
	}

	destinationFile, err := os.OpenFile(destinationPath, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0644)
	if err != nil {
		return
	}
	defer destinationFile.Close()

	// To make a self extracting archive, the `destinationPath` can be the executable that does the extraction.
	// For this reason, we set the `startoffset` to `os.SEEK_END`. This way we append the contents of the archive
	// after the executable. Check the README for an example of making a self-extracting archive.
	startoffset, err := destinationFile.Seek(0, os.SEEK_END)
	if err != nil {
		return
	}

	w := zip.NewWriter(destinationFile)
	w.RegisterCompressor(zip.Deflate, func(out io.Writer) (io.WriteCloser, error) {
		return flate.NewWriter(out, flate.BestCompression)
	})
	w.SetOffset(startoffset)

	for _, dir := range filesToZip {
		err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}

			linfo,err := os.Lstat(path)
			if err != nil {
				return err
			}

			fh, err := zip.FileInfoHeader(linfo)
			fh.Method = zip.Deflate
			if err != nil {
				return err
			}
			fh.Name = path

			writer, err := w.CreateHeader(fh)
			if err != nil {
				return err
			}
			if !info.IsDir() {
				var content []byte
				if info.Mode()&os.ModeSymlink != 0 {
					str, err := os.Readlink(path)
					if err != nil {
						return err
					}
					content = []byte(str)
				} else {
					content, err = os.ReadFile(path)
					if err != nil {
						return err
					}
				}

				_, err = writer.Write(content)
				if err != nil {
					return err
				}
			}
			return err
		})
	}
	err = w.Close()
	return
}

// Unzip unzips the file zippath and puts it in destination
func Unzip(zippath string, destination string) (err error) {
	zipReader, err := zip.OpenReader(zippath)
	if err != nil {
		return err
	}
	zipReader.RegisterDecompressor(zip.Store, func(in io.Reader) (io.ReadCloser) {
		return flate.NewReader(in)
	})
	defer zipReader.Close()

	for _, file := range zipReader.File {
		fullname := path.Join(destination, file.Name)
		if file.FileInfo().IsDir() {
			os.MkdirAll(fullname, file.FileInfo().Mode().Perm())
		} else if file.FileInfo().Mode()&os.ModeSymlink != 0 {
			os.MkdirAll(filepath.Dir(fullname), 0755)
			buf := new(strings.Builder)
			fileReadCloser, err := file.Open()
			if err != nil {
				return err
			}
			defer fileReadCloser.Close()

			_, err = io.CopyN(buf, fileReadCloser, file.FileInfo().Size())
			if err != nil {
				return err
			}
			err = os.Symlink(buf.String(), fullname)
			if err != nil {
				return err
			}
		} else {
			os.MkdirAll(filepath.Dir(fullname), 0755)
			perms := file.FileInfo().Mode().Perm()
			out, err := os.OpenFile(fullname, os.O_CREATE|os.O_RDWR, perms)
			if err != nil {
				return err
			}
			fileReadCloser, err := file.Open()
			if err != nil {
				return err
			}
			_, err = io.CopyN(out, fileReadCloser, file.FileInfo().Size())
			if err != nil {
				return err
			}
			fileReadCloser.Close()
			out.Close()

			mtime := file.FileInfo().ModTime()
			err = os.Chtimes(fullname, mtime, mtime)
			if err != nil {
				return err
			}
		}
	}
	return
}

// UnzipList Lists all the files in zip file
func UnzipList(path string) (list []string, err error) {
	r, err := zip.OpenReader(path)
	if err != nil {
		return
	}
	for _, f := range r.File {
		list = append(list, f.Name)
	}
	return
}

func CreateDirectoryIfNotExists(path string) (err error) {
	return os.MkdirAll(path, 0755)
}

func IsFileExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	} else if errors.Is(err, fs.ErrNotExist) {
		return false, nil
	} else {
		return false, err
	}
}

func RewritePaths(archiveContentsPath string, newStorePath string) (error) {
	archiveContents, err := os.Open(archiveContentsPath)
	if err != nil {
		return err
	}
	defer archiveContents.Close()

	// The top level files in the archive are the directories of the Nix packages so we can use those directory names
	// to get a list of all the package paths that need to be rewritten in the binaries.
	//
	// The 0 means return all files in the directory, as opposed to setting a max.
	topLevelFilesInArchive, err := archiveContents.Readdir(0)
	if err != nil {
		return err
	}
	newPackagePaths := make(map[string]string)
	oldStorePath := "/nix/store"
	extraSlashesCount := len(oldStorePath) - len(newStorePath)
	// The new store path must be the same length as the old one or it messes up the binary.
	newStorePathWithPadding := strings.Replace(newStorePath, "/", strings.Repeat("/", extraSlashesCount + 1), 1)
	for _, file := range topLevelFilesInArchive {
		name := file.Name()
		oldPackagePath := filepath.Join(oldStorePath, name)
		// I'm intentionally not using `filepath.Join` here since it normalizes the path which would remove the padding.
		newPackagePath := newStorePathWithPadding + "/" + name
		newPackagePaths[oldPackagePath] = newPackagePath
	}

	waitGroup := sync.WaitGroup{}
	err = filepath.Walk(archiveContentsPath, filepath.WalkFunc(func(path string, info os.FileInfo, err error) (error) {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		waitGroup.Add(1)
		go func(path string, info os.FileInfo) (err error) {
			defer waitGroup.Done()
			if info.Mode()&os.ModeSymlink != 0 {
				str, err := os.Readlink(path)
				if err != nil {
					return err
				}
				if strings.HasPrefix(str, oldStorePath) {
					newTarget := strings.Replace(str, oldStorePath, newStorePath, 1)
					err = os.Remove(path)
					if err != nil {
						return err
					}
					err = os.Symlink(newTarget, path)
					if err != nil {
						return err
					}
				}
				return nil
			}

			fileContents, err := ioutil.ReadFile(path)
			if err != nil {
				return err
			}
			newFileContents := fileContents
			for oldPackagePath, newPackagePath := range newPackagePaths {
				newFileContents = bytes.ReplaceAll(newFileContents, []byte(oldPackagePath), []byte(newPackagePath))
			}
			err = ioutil.WriteFile(path, []byte(newFileContents), 0)
			if err != nil {
				return err
			}
			return nil
		}(path, info)
		return nil
	}))
	if err != nil {
		return err
	}
	waitGroup.Wait()

	return nil
}

func GetNewStorePath() (prefix string, err error){
	rand.Seed(time.Now().UnixNano())
	charset := "abcdefghijklmnopqrstuvwxyz"
	var candidatePrefix string
	for i := 1; i <= 10; i++ {
		candidatePrefix = "/tmp/"

		// needs to be <= 5 since it will be appended to '/tmp/' and needs to be <= '/nix/store'
		stringLength := 4
		for i := 1; i <= stringLength; i++ {
			candidatePrefix = candidatePrefix + string(charset[rand.Intn(len(charset))])
		}

		isFileExists, err := IsFileExists(candidatePrefix)
		if err != nil {
			return "", err
		}
		if !isFileExists {
			return candidatePrefix, nil
		}
	}

	return "", errors.New("Unable to find a new store prefix")
}

func ExtractArchiveAndRewritePaths() (extractedArchivePath string, executableCachePath string, err error) {
	// no cache then write,
	// if cache then check if hash is same and cache location is same then use, otherwise delete hash folder and file and write new and use
	// cache: binary name folder, hash folder and file saying where this was extracted to
	userCachePath, err := os.UserCacheDir()
	if err != nil {
		return "", "", err
	}
	cachePath := filepath.Join(userCachePath, "nix-rootless-bundler")
	err = CreateDirectoryIfNotExists(cachePath)
	if err != nil {
		return "", "", err
	}

	executablePath, err := os.Executable()
	if err != nil {
		return "", "", err
	}

	executableName := filepath.Base(executablePath)
	executableCachePath = filepath.Join(cachePath, executableName)
	err = CreateDirectoryIfNotExists(executableCachePath)
	if err != nil {
		return "", "", err
	}

	executable, err := os.Open(executablePath)
	if err != nil {
		return "", "", err
	}
	defer executable.Close()
	hash := sha256.New()
	_, err = io.Copy(hash, executable)
	if err != nil {
		return "", "", err
	}
	executableChecksum := string(hash.Sum(nil))
	archiveContentsPath := filepath.Join(executableCachePath, "archive-contents")

	// The cache entry is still valid if the executable is the same and the cache is still in the same place, since
	// we rewrite the Nix store paths to point to the cache.
	expectedCacheKey := executableCachePath + executableChecksum
	cacheKeyPath := filepath.Join(executableCachePath, "cache-key.txt")
	isFileExists, err := IsFileExists(cacheKeyPath)
	if err != nil {
		return "", "", err
	}
	if isFileExists {
		cacheKey_Bytes, err := os.ReadFile(cacheKeyPath)
		if err != nil {
			return "", "", err
		}
		cacheKey := string(cacheKey_Bytes)
		if cacheKey == expectedCacheKey {
			return archiveContentsPath, executableCachePath, nil
		}
	}

	os.RemoveAll(archiveContentsPath)
	err = os.Mkdir(archiveContentsPath, 0755)
	if err != nil {
		return "", "", err
	}
	err = Unzip(executablePath, archiveContentsPath)
	if err != nil {
		return "", "", err
	}

	newStorePath, err := GetNewStorePath()
	if err != nil {
		return "", "", err
	}
	os.Remove(newStorePath)
	err = os.Symlink(archiveContentsPath, newStorePath)
	if err != nil {
		return "", "", err
	}

	err = RewritePaths(archiveContentsPath, newStorePath)
	if err != nil {
		return "", "", err
	}

	err = os.WriteFile(cacheKeyPath, []byte(expectedCacheKey), 0755)
	if err != nil {
		return "", "", err
	}

	return archiveContentsPath, executableCachePath, nil
}

func SelfExtractAndRunNixEntrypoint() (err error) {
	extractedArchivePath, cachePath, err := ExtractArchiveAndRewritePaths()
	if err != nil {
		return err
	}
	defer func() {
		deleteCacheEnvVariable := os.Getenv("NIX_ROOTLESS_BUNDLER_DELETE_CACHE")
		if len(deleteCacheEnvVariable) > 0 {
			os.RemoveAll(cachePath)
		}
	}()

	entrypointPath := filepath.Join(extractedArchivePath, "entrypoint")
	// First argument is the program name so we omit that.
	args := os.Args[1:]
	cmd := exec.Command(entrypointPath, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		return err
	}

	return nil
}
