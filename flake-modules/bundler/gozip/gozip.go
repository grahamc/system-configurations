package gozip

import (
	"archive/tar"
	"bytes"
	"crypto/sha256"
	"errors"
	"io"
	"io/fs"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
	"crypto/sha512"

	"github.com/klauspost/compress/zstd"
)

func GetTarReader(r io.Reader) (*tar.Reader, error) {
	zRdr, err := zstd.NewReader(r)
	if err != nil {
		return nil, err
	}

	return tar.NewReader(zRdr), nil
}

func generateBoundary() []byte {
	h := sha512.Sum512([]byte("boundary"))
	return h[:]
}
func Zip(destinationPath string, filesToZip []string) (err error) {
	destinationFile, err := os.OpenFile(destinationPath, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0644)
	if err != nil {
		return
	}
	defer destinationFile.Close()

	// To make a self extracting archive, the `destinationPath` can be the executable that does the extraction.
	// For this reason, we set the `startoffset` to `os.SEEK_END`. This way we append the contents of the archive
	// after the executable. Check the README for an example of making a self-extracting archive.
	_, err = destinationFile.Seek(0, os.SEEK_END)
	if err != nil {
		return err
	}
	_, err = destinationFile.Write(generateBoundary())
	if err != nil {
		log.Fatal("writing boundary to output file:", err)
	}

	zWrt, err := zstd.NewWriter(destinationFile, zstd.WithEncoderLevel(zstd.SpeedBestCompression))
	if err != nil {
		return err
	}
	defer zWrt.Close()
	tarWrt := tar.NewWriter(zWrt)
	defer tarWrt.Close()

	cd := "."
	for _, file := range filesToZip {
		rootDir := os.DirFS(cd)
		file = filepath.Clean(file)
		fs.WalkDir(rootDir, file, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if path == "." {
				return nil
			}

			var hdr tar.Header
			hdr.Name = path

			info, err := d.Info()
			if err != nil {
				return err
			}
			mode := info.Mode()
			hdr.Mode = int64(mode)

			switch mode.Type() {
				case fs.ModeDir:
					hdr.Typeflag = tar.TypeDir
				case fs.ModeSymlink:
					hdr.Typeflag = tar.TypeSymlink
					target, err := os.Readlink(filepath.Join(cd, path))
					if err != nil {
						return err
					}
					hdr.Linkname = target
				case 0: // regular file
					hdr.Typeflag = tar.TypeReg
					hdr.Size = info.Size()
				default:
					log.Fatalf("unsupported file type: %s", path)
			}

			err = tarWrt.WriteHeader(&hdr)
			if err != nil {
				return err
			}

			if mode.Type() == 0 {
				wf, err := os.Open(filepath.Join(cd, path))
				if err != nil {
					return err
				}
				_, err = io.Copy(tarWrt, wf)
				if err != nil {
					return err
				}
				wf.Close()
			}

			return nil
		})
	}

	return
}

func createFile(path string) (*os.File, error) {
	dir := filepath.Dir(path)
	err := os.MkdirAll(dir, 0755)
	if err != nil {
		return nil, err
	}
	f, err := os.Create(path)
	if err != nil {
		return nil, err
	}
	return f, nil
}

func cleanupDir(dir string) error {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		err := os.RemoveAll(filepath.Join(dir, entry.Name()))
		if err != nil {
			return err
		}
	}
	return nil
}

func cleanupAndDie(dir string, v ...interface{}) {
	err := cleanupDir(dir)
	if err != nil {
		log.Fatal(append([]interface{}{"got error:", err, "while cleaning up after:"}, v...))
	}
	log.Fatal(v...)
}

const keyLength = 16

func SeekToTar(file os.File) (os.File) {
	buf, err := os.ReadFile(file.Name())
	if err != nil {
		log.Fatal("reading itself:", err)
	}

	boundary := generateBoundary()
	bdyOff := bytes.Index(buf, boundary)

	if bdyOff == -1 {
		log.Fatal("no boundary")
	}

	payloadOff := bdyOff + len(boundary)

	_, err = file.Seek(int64(payloadOff), os.SEEK_SET)
	if err != nil {
		log.Fatal("seeking to start of payload:", err)
	}

	return file
}

// Unzip unzips the file zippath and puts it in destination
func Unzip(zippath string, destination string) (err error) {
	zipFile, err := os.Open(zippath)
	if err != nil {
		return err
	}
	defer zipFile.Close()
	SeekToTar(*zipFile)

	tarRdr, err := GetTarReader(zipFile)
	if err != nil {
		return err
	}

	os.RemoveAll(destination)
	err = os.Mkdir(destination, 0755)
	if err != nil {
		return err
	}

	for {
		hdr, err := tarRdr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		name := filepath.Clean(hdr.Name)
		if name == "." {
			continue
		}
		pathName := filepath.Join(destination, name)
		switch hdr.Typeflag {
		case tar.TypeReg:
			f, err := createFile(pathName)
			if err != nil {
				cleanupAndDie(destination, "creating file:", err)
			}

			_, err = io.Copy(f, tarRdr)
			if err != nil {
				cleanupAndDie(destination, "writing file:", err)
			}

			err = f.Chmod(os.FileMode(hdr.Mode))
			if err != nil {
				cleanupAndDie(destination, "setting mode of file:", err)
			}

			f.Close()
		case tar.TypeDir:
			// We choose to disregard directory permissions and use a default
			// instead. Custom permissions (e.g. read-only directories) are
			// complex to handle, both when extracting and also when cleaning
			// up the directory.
			err := os.Mkdir(pathName, 0755)
			if err != nil {
				cleanupAndDie(destination, "creating directory", err)
			}
		case tar.TypeSymlink:
			err := os.Symlink(hdr.Linkname, pathName)
			if err != nil {
				cleanupAndDie(destination, "creating symlink", err)
			}
		default:
			cleanupAndDie(destination, "unsupported file type in tar", hdr.Typeflag)
		}
	}

	return
}

// UnzipList Lists all the files in zip file
func UnzipList(path string) (list []string, err error) {
	zipFile, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer zipFile.Close()
	SeekToTar(*zipFile)

	tarRdr, err := GetTarReader(zipFile)
	if err != nil {
		return nil, err
	}

	for {
		hdr, err := tarRdr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		name := filepath.Clean(hdr.Name)
		if name == "." {
			continue
		}
		list = append(list, name)
	}

	return list, nil
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
	var oldAndNewPackagePaths []string
	oldStorePath := "/nix/store"
	extraSlashesCount := len(oldStorePath) - len(newStorePath)
	// The new store path must be the same length as the old one or it messes up the binary.
	newStorePathWithPadding := strings.Replace(newStorePath, "/", strings.Repeat("/", extraSlashesCount + 1), 1)
	for _, file := range topLevelFilesInArchive {
		name := file.Name()
		oldPackagePath := filepath.Join(oldStorePath, name)
		// I'm intentionally not using `filepath.Join` here since it normalizes the path which would remove the padding.
		newPackagePath := newStorePathWithPadding + "/" + name
		oldAndNewPackagePaths = append(oldAndNewPackagePaths, oldPackagePath, newPackagePath)
	}
	replacer := strings.NewReplacer(oldAndNewPackagePaths...)

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

			fileContents, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			newFileContents := replacer.Replace(string(fileContents))
			err = os.WriteFile(path, []byte(newFileContents), 0)
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
