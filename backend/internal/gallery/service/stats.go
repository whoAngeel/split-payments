package service

import (
	"time"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/gorm"
)

type StatsService struct {
	db *gorm.DB
}

func NewStatsService(db *gorm.DB) *StatsService {
	return &StatsService{db: db}
}

type DashboardStats struct {
	TotalRevenue    int64          `json:"total_revenue"`
	GalleryEarnings int64          `json:"gallery_earnings"`
	TotalPayments   int64          `json:"total_payments"`
	CompletedPayments int64        `json:"completed_payments"`
	PendingPayments int64          `json:"pending_payments"`
	RecentPayments  []model.Payment `json:"recent_payments"`
	SalesOverTime   []SalesPoint   `json:"sales_over_time"`
}

type SalesPoint struct {
	Date   string `json:"date"`
	Amount int64  `json:"amount"`
	Count  int64  `json:"count"`
}

type ArtisanStats struct {
	ArtisanID   uint   `json:"artisan_id"`
	ArtisanName string `json:"artisan_name"`
	TotalSales  int64  `json:"total_sales"`
	TotalAmount int64  `json:"total_amount"`
	ProductCount int64 `json:"product_count"`
}

type ProductStats struct {
	ProductID   uint   `json:"product_id"`
	ProductName string `json:"product_name"`
	ArtisanName string `json:"artisan_name"`
	TotalSales  int64  `json:"total_sales"`
	TotalAmount int64  `json:"total_amount"`
}

func (s *StatsService) GetDashboardStats(galleryID uint) (*DashboardStats, error) {
	stats := &DashboardStats{}

	s.db.Model(&model.Payment{}).
		Where("gallery_id = ? AND status = ?", galleryID, "completed").
		Select("COALESCE(SUM(gallery_share), 0)").
		Scan(&stats.GalleryEarnings)

	s.db.Model(&model.Payment{}).
		Where("gallery_id = ? AND status = ?", galleryID, "completed").
		Select("COALESCE(SUM(total_amount), 0)").
		Scan(&stats.TotalRevenue)

	s.db.Model(&model.Payment{}).
		Where("gallery_id = ?", galleryID).
		Count(&stats.TotalPayments)

	s.db.Model(&model.Payment{}).
		Where("gallery_id = ? AND status = ?", galleryID, "completed").
		Count(&stats.CompletedPayments)

	s.db.Model(&model.Payment{}).
		Where("gallery_id = ? AND status = ?", galleryID, "pending").
		Count(&stats.PendingPayments)

	s.db.Where("gallery_id = ?", galleryID).
		Order("created_at DESC").Limit(5).
		Find(&stats.RecentPayments)

	// Last 7 days sales
	sevenDaysAgo := time.Now().AddDate(0, 0, -7)
	var points []SalesPoint
	s.db.Model(&model.Payment{}).
		Select("DATE(created_at) as date, COALESCE(SUM(total_amount), 0) as amount, COUNT(*) as count").
		Where("gallery_id = ? AND status = ? AND created_at >= ?", galleryID, "completed", sevenDaysAgo).
		Group("DATE(created_at)").
		Order("date ASC").
		Find(&points)
	stats.SalesOverTime = points

	return stats, nil
}

func (s *StatsService) GetArtisanStats(galleryID uint) ([]ArtisanStats, error) {
	var stats []ArtisanStats
	s.db.Model(&model.Payment{}).
		Select("payments.artisan_id, artisans.name as artisan_name, COUNT(*) as total_sales, COALESCE(SUM(payments.total_amount), 0) as total_amount").
		Joins("JOIN artisans ON artisans.id = payments.artisan_id").
		Where("payments.gallery_id = ? AND payments.status = ?", galleryID, "completed").
		Group("payments.artisan_id, artisans.name").
		Order("total_amount DESC").
		Find(&stats)

	// Enrich with product count per artisan
	for i := range stats {
		s.db.Model(&model.Product{}).
			Where("artisan_id = ?", stats[i].ArtisanID).
			Count(&stats[i].ProductCount)
	}

	return stats, nil
}

func (s *StatsService) GetProductStats(galleryID uint) ([]ProductStats, error) {
	var stats []ProductStats
	s.db.Model(&model.Payment{}).
		Select("payments.product_id, products.name as product_name, artisans.name as artisan_name, COUNT(*) as total_sales, COALESCE(SUM(payments.total_amount), 0) as total_amount").
		Joins("JOIN products ON products.id = payments.product_id").
		Joins("JOIN artisans ON artisans.id = payments.artisan_id").
		Where("payments.gallery_id = ? AND payments.status = ?", galleryID, "completed").
		Group("payments.product_id, products.name, artisans.name").
		Order("total_amount DESC").
		Find(&stats)
	return stats, nil
}
