package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/sanderhahn/gozip"
)

func IsAnyInternalFlagPassed(flagSet *flag.FlagSet) bool {
	found := false
	flagSet.Visit(func(f *flag.Flag) {
		if f.Name == "internalCreate" || f.Name == "internalList" || f.Name == "internalExtract" {
			found = true
		}
	})
	return found
}

func main() {
	flagSet := flag.NewFlagSet("", flag.ContinueOnError)
	flagSet.SetOutput(io.Discard)
	var list, extract, create bool
	flagSet.BoolVar(&create, "internalCreate", false, "create zip (arguments: zipfile [files...])")
	flagSet.BoolVar(&list, "internalList", false, "list zip (arguments: zipfile)")
	flagSet.BoolVar(&extract, "internalExtract", false, "extract zip (arguments: zipfile [destination]")
	flagSet.Parse(os.Args[1:])

	if !IsAnyInternalFlagPassed(flagSet) {
		exitCode, err := gozip.SelfExtractAndRunNixEntrypoint()
		if err != nil {
			log.Fatal(err)
		}
		os.Exit(exitCode)
	}

	args := flagSet.Args()
	argc := len(args)
	if list && argc == 1 {
		path := args[0]
		list, err := gozip.UnzipList(path)
		if err != nil {
			log.Fatal(err)
		}
		for _, f := range list {
			fmt.Printf("%s\n", f)
		}
	} else if extract && (argc == 1 || argc == 2) {
		path := args[0]
		dest := "."
		if argc == 2 {
			dest = args[1]
		}
		err := gozip.Unzip(path, dest)
		if err != nil {
			log.Fatal(err)
		}
	} else if create && argc > 1 {
		err := gozip.Zip(args[0], args[1:])
		if err != nil {
			log.Fatal(err)
		}
	}
}
