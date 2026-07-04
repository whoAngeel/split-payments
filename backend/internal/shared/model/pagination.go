package model

type PageResponse struct {
	Items interface{} `json:"items"`
	Total int64       `json:"total"`
	Page  int         `json:"page"`
	Limit int         `json:"limit"`
}

type CursorResponse struct {
	Items      interface{} `json:"items"`
	NextCursor uint        `json:"next_cursor"`
}
