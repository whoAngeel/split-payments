package service

import (
	"regexp"
	"testing"
)

// captureMailer records the last mail instead of sending it.
type captureMailer struct {
	to      string
	subject string
	body    string
}

func (m *captureMailer) Send(to, subject, body string) error {
	m.to = to
	m.subject = subject
	m.body = body
	return nil
}

var codeRe = regexp.MustCompile(`\b\d{6}\b`)

func requestCode(t *testing.T, svc *AuthService, mail *captureMailer, email string) string {
	t.Helper()
	if err := svc.RequestPasswordReset(email); err != nil {
		t.Fatalf("request reset failed: %v", err)
	}
	code := codeRe.FindString(mail.body)
	if code == "" {
		t.Fatalf("no code found in mail body: %q", mail.body)
	}
	return code
}

func TestAuthService_PasswordResetFlow(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")
	mail := &captureMailer{}
	svc.SetMailer(mail)

	_, _, err := svc.Register("reset@test.com", "oldpassword", "Test", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	code := requestCode(t, svc, mail, "reset@test.com")
	if mail.to != "reset@test.com" {
		t.Errorf("mail sent to %s, expected reset@test.com", mail.to)
	}

	if err := svc.ResetPassword("reset@test.com", code, "newpassword123"); err != nil {
		t.Fatalf("reset failed: %v", err)
	}

	if _, _, err := svc.Login("reset@test.com", "oldpassword"); err == nil {
		t.Error("old password still works after reset")
	}
	if _, _, err := svc.Login("reset@test.com", "newpassword123"); err != nil {
		t.Errorf("new password does not work: %v", err)
	}
}

func TestAuthService_PasswordResetUnknownEmail(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")
	mail := &captureMailer{}
	svc.SetMailer(mail)

	if err := svc.RequestPasswordReset("nobody@test.com"); err != nil {
		t.Fatalf("expected silent success for unknown email, got: %v", err)
	}
	if mail.to != "" {
		t.Error("mail was sent for unknown email")
	}
}

func TestAuthService_PasswordResetWrongCode(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")
	mail := &captureMailer{}
	svc.SetMailer(mail)

	_, _, err := svc.Register("wrong@test.com", "oldpassword", "Test", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	code := requestCode(t, svc, mail, "wrong@test.com")

	badCode := "000000"
	if badCode == code {
		badCode = "000001"
	}
	if err := svc.ResetPassword("wrong@test.com", badCode, "newpassword123"); err == nil {
		t.Fatal("expected error for wrong code")
	}

	// correct code still works after one failed attempt
	if err := svc.ResetPassword("wrong@test.com", code, "newpassword123"); err != nil {
		t.Fatalf("reset with correct code failed: %v", err)
	}
}

func TestAuthService_PasswordResetCodeSingleUse(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")
	mail := &captureMailer{}
	svc.SetMailer(mail)

	_, _, err := svc.Register("single@test.com", "oldpassword", "Test", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	code := requestCode(t, svc, mail, "single@test.com")

	if err := svc.ResetPassword("single@test.com", code, "newpassword123"); err != nil {
		t.Fatalf("first reset failed: %v", err)
	}
	if err := svc.ResetPassword("single@test.com", code, "otherpassword456"); err == nil {
		t.Fatal("expected error reusing code")
	}
}

func TestAuthService_PasswordResetMaxAttempts(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")
	mail := &captureMailer{}
	svc.SetMailer(mail)

	_, _, err := svc.Register("attempts@test.com", "oldpassword", "Test", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	code := requestCode(t, svc, mail, "attempts@test.com")

	badCode := "000000"
	if badCode == code {
		badCode = "000001"
	}
	for range maxResetAttempts {
		if err := svc.ResetPassword("attempts@test.com", badCode, "newpassword123"); err == nil {
			t.Fatal("expected error for wrong code")
		}
	}

	// exhausted: even the correct code is rejected
	if err := svc.ResetPassword("attempts@test.com", code, "newpassword123"); err == nil {
		t.Fatal("expected error after max attempts")
	}
}

func TestAuthService_PasswordResetNewCodeInvalidatesOld(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")
	mail := &captureMailer{}
	svc.SetMailer(mail)

	_, _, err := svc.Register("rotate@test.com", "oldpassword", "Test", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	oldCode := requestCode(t, svc, mail, "rotate@test.com")
	newCode := requestCode(t, svc, mail, "rotate@test.com")

	if oldCode != newCode {
		if err := svc.ResetPassword("rotate@test.com", oldCode, "newpassword123"); err == nil {
			t.Fatal("old code still valid after requesting a new one")
		}
	}
	if err := svc.ResetPassword("rotate@test.com", newCode, "newpassword123"); err != nil {
		t.Fatalf("reset with new code failed: %v", err)
	}
}
