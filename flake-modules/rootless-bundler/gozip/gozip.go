package gozip

import (
	"archive/zip"
	"errors"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"bytes"
	"strings"
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
func Zip(path string, dirs []string) (err error) {
	if IsZip(path) {
		return errors.New(path + " is already a zip file")
	}

	f, err := os.OpenFile(path, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0644)
	if err != nil {
		return
	}
	defer f.Close()

	startoffset, err := f.Seek(0, os.SEEK_END)
	if err != nil {
		return
	}

	w := zip.NewWriter(f)
	w.SetOffset(startoffset)

	for _, dir := range dirs {
		err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}

			linfo,err := os.Lstat(path)
			if err != nil {
				return err
			}

			fh, err := zip.FileInfoHeader(linfo)
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

func Entrypoint() (err error) {
	exePath, err := os.Executable()
	if err != nil {
		return err
	}
	os.RemoveAll("out")
	err = os.Mkdir("out", 0755)
	if err != nil {
		return err
	}
	Unzip(exePath, "out")

	os.Remove("/tmp/rew")
	wd, err := os.Getwd()
	if err != nil {
		return err
	}
	err = os.Symlink(wd + "/out", "/tmp/rew")
	if err != nil {
		return err
	}
	outDir, err := os.Open("./out")
	if err != nil {
		return err
	}
	outDirFiles, err := outDir.Readdir(0)
	if err != nil {
		return err
	}
	hashes := make(map[string]string)
	for _, file := range outDirFiles {
		name := file.Name()
		oldpath := "/nix/store/" + name
		newPath := "/tmp/rew///" + name
		hashes[oldpath] = newPath
	}
	err = filepath.Walk("./out", filepath.WalkFunc(func(path string, info os.FileInfo, err error) (error) {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		if info.Mode()&os.ModeSymlink != 0 {
			str, err := os.Readlink(path)
			if err != nil {
				return err
			}
			if strings.HasPrefix(str, "/nix/store/") {
				newTarget := strings.Replace(str, "/nix/store/", "/tmp/rew/", 1)
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

		read, err := ioutil.ReadFile(path)
		if err != nil {
			return err
		}
		newContents := read
		for old, new := range hashes {
			newContents = bytes.ReplaceAll(newContents, []byte(old), []byte(new))
		}
		err = ioutil.WriteFile(path, []byte(newContents), 0)
		if err != nil {
			return err
		}

		return nil
	}))
	if err != nil {
		return err
	}

	cmd := exec.Command("./out/entrypoint")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		return
	}

	return nil
}
