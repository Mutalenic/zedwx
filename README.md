# **ZEDWX: Zambia-Specific Weather Application**  

[![Ruby](https://img.shields.io/badge/Ruby-3.2+-red.svg)](https://www.ruby-lang.org/)  
[![Rails](https://img.shields.io/badge/Rails-7.0+-red.svg)](https://rubyonrails.org)

A weather application providing hyper-local forecasts for Zambian cities, built with **Ruby on Rails** and **React**.

---

## 🌟 **Key Features**  

### **Frontend:**  
- Real-time weather display for Zambian cities.  
- Multi-language support (English + Zambian languages).  
- Responsive, mobile-first design.  

### **Backend:**  
- Integration with Open-Meteo API for weather data.  
- Location validation for Zambian cities.  
- Redis-based caching to optimize weather data access.  
- Secure API endpoints to protect sensitive information.  
- Historical weather data storage for analytics and trends.  

---

## 🔧 **Why a Backend is Crucial for ZEDWX**  

### 1. **API Management & Security:**  
   - Protects Open-Meteo API credentials.  
   - Prevents direct exposure of API endpoints to clients.  
   - Implements rate limiting (e.g., 100 requests/hour per IP).  

### 2. **Data Processing:**  
   - Transforms raw API responses into Zambia-specific formats.  
   - Converts weather codes into local terminology (e.g., "Mvula" for rain).  
   - Adds Zambian timezone handling (Central Africa Time - CAT).  

### 3. **Location Validation:**  
   - Ensures only supported Zambian cities are queried.  
   - Maintains an accurate geolocation database for Zambian cities.  

### 4. **Caching System:**  
   - Reduces API calls to Open-Meteo by over 60% using Redis.  
   - Stores frequently accessed data (e.g., Lusaka weather).  
   - Implements a 15-minute cache expiration strategy.  

### 5. **Scalability:**  
   - Supports future features like historical data analysis.  
   - Lays the groundwork for a planned SMS weather alert system.  
   - Enables user preference storage (coming in v2).  

### 6. **Localization Hub:**  
   - Centralizes translation logic for Zambian languages.  
   - Maintains dictionaries of weather terminology.  
   - Formats dates and times according to Zambia’s standards.  

---

## 🚀 **Getting Started**  

### **Prerequisites:**  
- Ruby 3.2+  
- PostgreSQL  
- Redis  

### **Setup:**  
1. Clone the repository:  
   ```bash
   git clone https://github.com/yourusername/zedwx.git
   cd zedwx/backend
   ```  

2. Install dependencies:  
   ```bash
   bundle install
   ```  

3. Configure the database:  
   ```bash
   rails db:create && rails db:migrate
   rails db:seed  # Loads Zambian cities into the database
   ```  

4. Start the Rails server:  
   ```bash
   rails s -p 3001
   ```  

5. Test the endpoint:  
   ```bash
   curl http://localhost:3001/api/v1/weather/current?location=Lusaka
   ```  

---

## 🛠 **Tech Stack**  

### **Backend:**  
| Component         | Technology         |  
|--------------------|--------------------|  
| Framework          | Ruby on Rails 7    |  
| API Client         | Faraday            |  
| Caching            | Redis              |  
| Database           | PostgreSQL         |  
| API Documentation  | Swagger (planned)  |  

### **Frontend:**  
| Component         | Technology         |  
|--------------------|--------------------|  
| Framework          | React 18           |  
| State Management   | Redux Toolkit      |  
| Styling            | Tailwind CSS       |  
| Localization       | i18next            |  

---

## 🤝 **Contributing**  
Contributions are welcome to make ZEDWX better! Areas to contribute include:  
- Adding new Zambian cities.  
- Improving weather code translations.  
- Enhancing caching strategies.  

Please see the contribution guidelines for more details.  

---

## 📄 **License**  
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.  

---

### **Weather data powered by Open-Meteo**  
