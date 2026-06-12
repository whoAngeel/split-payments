package model

type SplitRequest struct {
	SenderWallet string   `json:"sender_wallet"`
	Shares       []Share  `json:"shares"`
}

type Share struct {
	Wallet string `json:"wallet"`
	Amount string `json:"amount"`
}

type SplitResponse struct {
	SessionID   string `json:"session_id"`
	RedirectURL string `json:"redirect_url"`
}
