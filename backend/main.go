package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var jwtKey = []byte("FixItMarketplace_Secret_2026") // Use an environment variable in production

type Claims struct {
	UserID uint   `json:"user_id"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

// 1. User Model: Homeowners and Tradespeople 
type User struct {
	gorm.Model
	Name         string `json:"name" gorm:"not null"`
	Email        string `json:"email" gorm:"unique;not null"`
	PasswordHash string `json:"-"`
	Role         string `json:"role"` // "homeowner" or "tradesperson"
}

// 2. Professional Profile: Specialty, License, and "On-Duty" status 
type ProfessionalProfile struct {
	gorm.Model
	UserID        uint   `json:"user_id"`
	User          User   `gorm:"foreignKey:UserID"`
	TradeCategory string `json:"trade_category"` // Plumbing, Electrical, HVAC, Carpentry, Appliance Repair 
	LicenseNumber string `json:"license_number"`
	IsVerified    bool   `json:"is_verified" gorm:"default:false"`
	IsOnDuty      bool   `json:"is_on_duty" gorm:"default:false"` // Real-time tracking 
}

// 3. Booking Model: Service type, status, and location 
type Booking struct {
	gorm.Model
	HomeownerID    uint    `json:"homeowner_id"`
	TradespersonID uint    `json:"tradesperson_id"`
	ServiceType    string  `json:"service_type"` // Must be an Essential Trade [cite: 4]
	Status         string  `json:"status"`       // "Pending", "In-Progress", "Completed" 
	Location       string  `json:"location"`     // Hyperlocal focus [cite: 4]
}

// 4. Review Model: The mandatory feedback loop to build community trust 
type Review struct {
	gorm.Model
	BookingID uint   `json:"booking_id"`
	Rating    int    `json:"rating"`  // 1 to 5 stars
	Comment   string `json:"comment"`
}

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func GenerateToken(userID uint, role string) (string, error) {
	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtKey)
}

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString := c.GetHeader("Authorization")
		if tokenString == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization required"})
			c.Abort()
			return
		}

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		// Pass UserID and Role to the next function
		c.Set("userID", claims.UserID)
		c.Set("role", claims.Role)
		c.Next()
	}
}

func main() {
	// 1. Connection String
	dsn := "host=localhost user=postgres password=BIGBOSS dbname=fixit port=5432 sslmode=disable"

	// 2. Open Connection
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	fmt.Println("Database connection successful!")

	// 3. Updated Migration: All 4 tables are created here
	err = db.AutoMigrate(&User{}, &ProfessionalProfile{}, &Booking{}, &Review{})
	if err != nil {
		log.Fatal("Migration failed:", err)
	}

	fmt.Println("Database migration with 4 tables completed successfully!")

	r := gin.Default()

    // 1. Registration Route
    r.POST("/register", func(c *gin.Context) {
        var input struct {
            Name     string `json:"name"`
            Email    string `json:"email"`
            Password string `json:"password"`
            Role     string `json:"role"`
        }
        if err := c.ShouldBindJSON(&input); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid data"})
            return
        }

        hashed, _ := HashPassword(input.Password)
        user := User{Name: input.Name, Email: input.Email, PasswordHash: hashed, Role: input.Role}
        db.Create(&user)

        c.JSON(http.StatusOK, gin.H{"message": "Registration successful"})
    })

    // 2. Login Route
    r.POST("/login", func(c *gin.Context) {
        var loginData struct{ Email, Password string }
        c.ShouldBindJSON(&loginData)

        var user User
        if err := db.Where("email = ?", loginData.Email).First(&user).Error; err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
            return
        }

        if !CheckPasswordHash(loginData.Password, user.PasswordHash) {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Wrong password"})
            return
        }

        token, _ := GenerateToken(user.ID, user.Role)
        c.JSON(http.StatusOK, gin.H{"token": token})
    })

    // 3. Protected Group (Requires JWT)
    api := r.Group("/api")
    api.Use(AuthMiddleware())
    {
        api.GET("/profile", func(c *gin.Context) {
            userID, _ := c.Get("userID")
            c.JSON(http.StatusOK, gin.H{"user_id": userID, "status": "Authenticated"})
        })
    }

    r.Run(":8080")
}