package logging

import (
	"os"
	"strings"

	"github.com/charmbracelet/log"
)

type Config struct {
	Service string
	Level   string
	Format  string
}

func New(cfg Config) *log.Logger {
	opts := log.Options{
		Prefix:          cfg.Service + " ",
		ReportTimestamp: true,
		Level:           parseLevel(cfg.Level),
	}

	switch strings.ToLower(cfg.Format) {
	case "json":
		opts.Formatter = log.JSONFormatter
	case "logfmt":
		opts.Formatter = log.LogfmtFormatter
	default:
		opts.Formatter = log.TextFormatter
	}

	logger := log.NewWithOptions(os.Stderr, opts)
	return logger
}

func parseLevel(level string) log.Level {
	switch strings.ToLower(level) {
	case "debug":
		return log.DebugLevel
	case "warn":
		return log.WarnLevel
	case "error":
		return log.ErrorLevel
	default:
		return log.InfoLevel
	}
}
