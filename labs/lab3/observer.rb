# ============================================
# LAB 3: Observer Pattern
# ============================================
# The Observer pattern defines a one-to-many dependency between objects
# so that when one object changes state, all its dependents are notified.
# Run this file with: ruby observer.rb

# Exercise 1: Implement a Weather Station with Observers
# The WeatherStation is the subject, and displays are observers

class WeatherStation
  # TODO: Initialize with an empty array of observers
  # TODO: Add temperature, humidity, and pressure attributes
  attr_reader :temperature, :humidity, :pressure

  def initialize
    @observers = []
    @temperature = 0
    @humidity = 0
    @pressure = 0
  end
  
  # TODO: Implement attach method to add an observer
  def attach(observer)
    @observers << observer unless @observers.include?(observer)
  end
  
  # TODO: Implement detach method to remove an observer
  def detach(observer)
    @observers.delete(observer)
  end
  
  # TODO: Implement notify method to call update on all observers
  def notify
    @observers.each { |obs| obs.update(self) }
  end
  
  def set_measurements(temperature, humidity, pressure)
    @temperature = temperature
    @humidity = humidity
    @pressure = pressure
    notify
  end
  

end

class CurrentConditionsDisplay
  # TODO: Implement update method
  # Return "Current conditions: #{temperature}°C, #{humidity}% humidity"
  
  def update(weather_station)
    temp = weather_station.temperature
    hum  = weather_station.humidity
    "Current conditions: #{temp}°C, #{hum}% humidity"
  end
end

class StatisticsDisplay
  def initialize
    @temperatures = []
  end
  
  # TODO: Implement update method
  # Store temperature and return average
  # Return "Avg temperature: #{average}°C"
  
  def update(weather_station)
    temp = weather_station.temperature
    @temperatures << temp.to_f

    avg = @temperatures.sum / @temperatures.size
    "Avg temperature: %.2f°C" % avg
  end
end

# Exercise 2: Implement a Stock Market Observer
# Stock is the subject, investors are observers

class Stock
  attr_reader :symbol, :price
  
  def initialize(symbol, initial_price)
    @symbol = symbol
    @price = initial_price
    # TODO: Initialize observers array
    @observers = []
  end
  
  # TODO: Implement subscribe method to add observer
  def subscribe(observer)
    @observers << observer unless @observers.include?(observer)
  end
  
  # TODO: Implement unsubscribe method to remove observer
  def unsubscribe(observer)
    @observers.delete(observer)
  end
  
  def update_price(new_price)
    old_price = @price
    @price = new_price
    # TODO: Notify all observers with old_price and new_price
    notify_observers(old_price, new_price)
  end
  
  # TODO: Implement notify_observers method
  def notify_observers(old_price, new_price)
    @observers.each do |observer|
      observer.on_price_change(self, old_price, new_price)
  end
end
end


class Investor
  attr_reader :name, :notifications
  
  def initialize(name)
    @name = name
    @notifications = []
  end
  
  # TODO: Implement on_price_change method
  # Store notification: "#{stock.symbol}: #{old_price} -> #{new_price}"
  # Return the notification string
  
  def on_price_change(stock, old_price, new_price)
    notification = "#{stock.symbol}: #{old_price} -> #{new_price}"
    @notifications << notification
    notification
  end
end

# Exercise 3: Implement Event System using Ruby's Observable module
# Note: Ruby's Observable is deprecated, so we'll implement a simple version

module Observable
  # TODO: Implement this module to add observer functionality
  # Methods needed: add_observer, delete_observer, notify_observers
  
  def add_observer(observer)
    @observers ||= []
    # TODO: Add observer to array if not already present
    @observers << observer unless @observers.include?(observer)
  end
  
  def delete_observer(observer)
    @observers ||= []
    @observers.delete(observer)
  end
  
  def notify_observers(data = nil)
    @observers ||= []
    # TODO: Call update method on each observer with self and data
    @observers.each do |observer|
      observer.update(self, data)
  end
end
end

class NewsAgency
  include Observable
  
  attr_reader :latest_news
  
  def publish_news(news)
    @latest_news = news
    # TODO: Notify all observers with the news
    notify_observers(news)
  end
end

class NewsSubscriber
  attr_reader :name, :received_news
  
  def initialize(name)
    @name = name
    @received_news = []
  end
  
  # TODO: Implement update method
  # Store news in received_news array
  # news_agency is the first parameter, news is the second
  
  def update(news_agency, news)
    @received_news << news
  end
end

# ============================================
# TEST CASES - Do not modify below this line
# ============================================

def run_tests
  tests_passed = 0
  total_tests = 0
  
  puts "Testing Observer Pattern..."
  puts "=" * 40
  
  # Test 1: WeatherStation with CurrentConditionsDisplay
  total_tests += 1
  begin
    station = WeatherStation.new
    display = CurrentConditionsDisplay.new
    station.attach(display)
    station.set_measurements(25, 65, 1013)
    
    result = display.update(station)
    if result == "Current conditions: 25°C, 65% humidity"
      tests_passed += 1
      puts "✓ Test 1 passed: CurrentConditionsDisplay works"
    else
      puts "✗ Test 1 failed: Display output incorrect"
    end
  rescue => e
    puts "✗ Test 1 failed: #{e.message}"
  end
  
  # Test 2: WeatherStation with StatisticsDisplay
  total_tests += 1
  begin
    station = WeatherStation.new
    stats = StatisticsDisplay.new
    station.attach(stats)
    station.set_measurements(20, 60, 1010)
    station.set_measurements(25, 65, 1013)
    station.set_measurements(22, 63, 1011)
    
    result = stats.update(station)
    if result.include?("22") || result.include?("22.33")
      tests_passed += 1
      puts "✓ Test 2 passed: StatisticsDisplay calculates average"
    else
      puts "✗ Test 2 failed: Statistics incorrect"
    end
  rescue => e
    puts "✗ Test 2 failed: #{e.message}"
  end
  
  # Test 3: WeatherStation detach observer
  total_tests += 1
  begin
    station = WeatherStation.new
    display = CurrentConditionsDisplay.new
    station.attach(display)
    station.detach(display)
    
    # Should not raise error even though observer is detached
    station.set_measurements(30, 70, 1015)
    tests_passed += 1
    puts "✓ Test 3 passed: Observer detached successfully"
  rescue => e
    puts "✗ Test 3 failed: #{e.message}"
  end
  
  # Test 4: Stock price update notifies investors
  total_tests += 1
  begin
    stock = Stock.new("AAPL", 150.0)
    investor = Investor.new("John")
    stock.subscribe(investor)
    stock.update_price(155.0)
    
    if investor.notifications.length > 0 && 
       investor.notifications[0].include?("AAPL") &&
       investor.notifications[0].include?("150") &&
       investor.notifications[0].include?("155")
      tests_passed += 1
      puts "✓ Test 4 passed: Investor notified of price change"
    else
      puts "✗ Test 4 failed: Investor not notified correctly"
    end
  rescue => e
    puts "✗ Test 4 failed: #{e.message}"
  end
  
  # Test 5: Multiple investors
  total_tests += 1
  begin
    stock = Stock.new("GOOGL", 2800.0)
    investor1 = Investor.new("Alice")
    investor2 = Investor.new("Bob")
    stock.subscribe(investor1)
    stock.subscribe(investor2)
    stock.update_price(2850.0)
    
    if investor1.notifications.length > 0 && investor2.notifications.length > 0
      tests_passed += 1
      puts "✓ Test 5 passed: Multiple investors notified"
    else
      puts "✗ Test 5 failed: Not all investors notified"
    end
  rescue => e
    puts "✗ Test 5 failed: #{e.message}"
  end
  
  # Test 6: Unsubscribe from stock
  total_tests += 1
  begin
    stock = Stock.new("TSLA", 700.0)
    investor = Investor.new("Charlie")
    stock.subscribe(investor)
    stock.update_price(720.0)
    stock.unsubscribe(investor)
    stock.update_price(740.0)
    
    if investor.notifications.length == 1
      tests_passed += 1
      puts "✓ Test 6 passed: Unsubscribe works"
    else
      puts "✗ Test 6 failed: Unsubscribe didn't work"
    end
  rescue => e
    puts "✗ Test 6 failed: #{e.message}"
  end
  
  # Test 7: NewsAgency with subscribers
  total_tests += 1
  begin
    agency = NewsAgency.new
    subscriber1 = NewsSubscriber.new("Reader1")
    subscriber2 = NewsSubscriber.new("Reader2")
    agency.add_observer(subscriber1)
    agency.add_observer(subscriber2)
    agency.publish_news("Breaking news!")
    
    if subscriber1.received_news.include?("Breaking news!") &&
       subscriber2.received_news.include?("Breaking news!")
      tests_passed += 1
      puts "✓ Test 7 passed: News subscribers notified"
    else
      puts "✗ Test 7 failed: Subscribers not notified correctly"
    end
  rescue => e
    puts "✗ Test 7 failed: #{e.message}"
  end
  
  # Test 8: Remove news subscriber
  total_tests += 1
  begin
    agency = NewsAgency.new
    subscriber = NewsSubscriber.new("Reader")
    agency.add_observer(subscriber)
    agency.publish_news("News 1")
    agency.delete_observer(subscriber)
    agency.publish_news("News 2")
    
    if subscriber.received_news.length == 1
      tests_passed += 1
      puts "✓ Test 8 passed: Observer removed successfully"
    else
      puts "✗ Test 8 failed: Observer removal didn't work"
    end
  rescue => e
    puts "✗ Test 8 failed: #{e.message}"
  end
  
  puts "\n" + "=" * 40
  if tests_passed == total_tests
    puts "🎉 All tests passed! (#{tests_passed}/#{total_tests})"
    puts "Excellent! You've mastered the Observer pattern!"
  else
    puts "Tests passed: #{tests_passed}/#{total_tests}"
    puts "Keep working on the remaining exercises."
  end
  puts "=" * 40
end

# Run the tests
run_tests
