package mailer

import (
	"fmt"
	"net/smtp"

	"github.com/charmbracelet/log"
	resend "github.com/resend/resend-go/v3"
)

type Mailer interface {
	Send(to, subject, body string) error
}

// SMTPMailer sends mail through an SMTP server using PLAIN auth over
// STARTTLS (port 587 style, e.g. Gmail with an app password).
type SMTPMailer struct {
	host     string
	port     string
	user     string
	password string
	from     string
}

func NewSMTP(host, port, user, password, from string) *SMTPMailer {
	if port == "" {
		port = "587"
	}
	if from == "" {
		from = user
	}
	return &SMTPMailer{host: host, port: port, user: user, password: password, from: from}
}

func (m *SMTPMailer) Send(to, subject, body string) error {
	msg := fmt.Appendf(nil,
		"From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s\r\n",
		m.from, to, subject, body,
	)
	auth := smtp.PlainAuth("", m.user, m.password, m.host)
	if err := smtp.SendMail(m.host+":"+m.port, auth, m.from, []string{to}, msg); err != nil {
		return fmt.Errorf("sending mail: %w", err)
	}
	return nil
}

// ResendMailer sends mail through the Resend API.
type ResendMailer struct {
	client *resend.Client
	from   string
}

func NewResend(apiKey, from string) *ResendMailer {
	return &ResendMailer{client: resend.NewClient(apiKey), from: from}
}

func (m *ResendMailer) Send(to, subject, body string) error {
	params := &resend.SendEmailRequest{
		From:    m.from,
		To:      []string{to},
		Subject: subject,
		Text:    body,
	}
	_, err := m.client.Emails.Send(params)
	if err != nil {
		return fmt.Errorf("resend: %w", err)
	}
	return nil
}

// LogMailer writes the mail to the application log instead of sending it.
// Used when neither SMTP nor Resend is configured.
type LogMailer struct {
	logger *log.Logger
}

func NewLog(logger *log.Logger) *LogMailer {
	return &LogMailer{logger: logger}
}

func (m *LogMailer) Send(to, subject, body string) error {
	m.logger.Warn("no mailer configured, mail written to log", "to", to, "subject", subject, "body", body)
	return nil
}
