package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"
)

type client struct {
	base string
	key  string
	http *http.Client
}

func (c *client) get(path string, params url.Values) (int, []byte, error) {
	req, err := http.NewRequest(http.MethodGet, c.base+path+"?"+params.Encode(), nil)
	if err != nil {
		return 0, nil, err
	}
	if c.key != "" {
		req.Header.Set("X-API-Key", c.key)
	}
	res, err := c.http.Do(req)
	if err != nil {
		return 0, nil, err
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	return res.StatusCode, body, err
}

func main() {
	base := flag.String("base", "http://127.0.0.1:8000", "API base URL")
	year := flag.Int("year", 2021, "checkout year")
	limit := flag.Int("limit", 5, "top limit")
	format := flag.String("format", "json", "json or xml")
	q := flag.String("q", "", "search query (optional)")
	flag.Parse()

	c := &client{base: *base, key: os.Getenv("API_KEY"), http: &http.Client{Timeout: 10 * time.Second}}

	status, body, err := c.get("/titles/top", url.Values{
		"year":   {fmt.Sprint(*year)},
		"limit":  {fmt.Sprint(*limit)},
		"format": {*format},
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("GET /titles/top -> %d\n", status)
	if status != http.StatusOK {
		fmt.Println(string(body))
		os.Exit(1)
	}
	if *format == "xml" {
		fmt.Println(string(body))
	} else {
		var rows []struct {
			Title string `json:"title"`
			Total int64  `json:"total"`
		}
		if err := json.Unmarshal(body, &rows); err != nil {
			log.Fatal(err)
		}
		for i, r := range rows {
			fmt.Printf("%d. %s (%d)\n", i+1, r.Title, r.Total)
		}
	}

	if *q == "" {
		return
	}
	status, body, err = c.get("/search", url.Values{"q": {*q}})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("GET /search?q=%s -> %d\n", *q, status)
	fmt.Println(string(body))
}
