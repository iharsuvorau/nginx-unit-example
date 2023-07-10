package main

import (
	"io"
	"net/http"

	unit "unit.nginx.org/go"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "Hello, Go on Unit!")
	})
	unit.ListenAndServe(":9000", nil)
}
