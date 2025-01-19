-- Create Database
CREATE DATABASE IF NOT EXISTS FoodDeliverySystem;
USE FoodDeliverySystem;

-- Customer Table
CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100),
    address VARCHAR(255),
    contact_number VARCHAR(20),
    email VARCHAR(100)
);

-- Delivery Agent Table
CREATE TABLE DeliveryAgent (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    agent_name VARCHAR(100),
    contact_number VARCHAR(20),
    vehicle_type VARCHAR(50)
);

-- Restaurant Table
CREATE TABLE Restaurant (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_name VARCHAR(100),
    address VARCHAR(255),
    contact_number VARCHAR(20)
);

-- Menu Table
CREATE TABLE Menu (
    menu_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT,
    item_name VARCHAR(100),
    item_description VARCHAR(255),
    price DECIMAL(10, 2),
    FOREIGN KEY (restaurant_id) REFERENCES Restaurant(restaurant_id)
);

-- Inventory Table (NEW)
CREATE TABLE Inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT,
    menu_id INT,
    stock_quantity INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (restaurant_id) REFERENCES Restaurant(restaurant_id),
    FOREIGN KEY (menu_id) REFERENCES Menu(menu_id)
);

-- Orders Table
CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    total_amount DECIMAL(10, 2),
    order_status VARCHAR(20) DEFAULT 'Pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES Restaurant(restaurant_id)
);

-- OrderItem Table
CREATE TABLE OrderItem (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    menu_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (menu_id) REFERENCES Menu(menu_id)
);

DELIMITER //

CREATE TRIGGER UpdateInventoryAfterOrder
AFTER INSERT ON OrderItem
FOR EACH ROW
BEGIN
    DECLARE stock INT;

    -- Fetch the current stock level of the ordered item in the Inventory
    SELECT stock_quantity INTO stock 
    FROM Inventory
    WHERE restaurant_id = (SELECT restaurant_id FROM Orders WHERE order_id = NEW.order_id)
      AND menu_id = NEW.menu_id;

    -- Check if the stock is sufficient
    IF stock >= NEW.quantity THEN
        -- Update the stock level in the Inventory
        UPDATE Inventory
        SET stock_quantity = stock - NEW.quantity
        WHERE restaurant_id = (SELECT restaurant_id FROM Orders WHERE order_id = NEW.order_id)
          AND menu_id = NEW.menu_id;
    ELSE
        -- Signal an error if stock is insufficient
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock for the requested item.';
    END IF;
END //

DELIMITER ;

DELIMITER $$

CREATE FUNCTION calculate_total_price(order_id INT) 
RETURNS DECIMAL(10, 2) 
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10, 2);
    
    -- Calculate the total price by summing the price * quantity of each item in the order
    SELECT SUM(price * quantity) INTO total
    FROM OrderItem
    WHERE order_id = order_id;
    
    -- Return the calculated total price
    RETURN total;
END $$

DELIMITER ;



INSERT INTO Restaurant (restaurant_name, address, contact_number) VALUES
('Pizza Palace', '101 Italian Ave, Springfield', '555-1111'),
('Burger Barn', '202 American Rd, Springfield', '555-2222'),
('Sushi Spot', '303 Tokyo St, Springfield', '555-3333'),
('Taco Town', '404 Mexico Ln, Springfield', '555-4444'),
('Pasta Paradise', '505 Rome Ave, Springfield', '555-5555'),
('Curry Corner', '606 India Blvd, Springfield', '555-6666'),
('Steak House', '707 Texas St, Springfield', '555-7777'),
('Dragon Dine', '808 China Dr, Springfield', '555-8888'),
('Falafel Factory', '909 Middle East St, Springfield', '555-9999'),
('Greens & Grains', '1000 Vegan Ave, Springfield', '555-0000');

INSERT INTO Customer (customer_name, address, contact_number, email) VALUES
('John Doe', '123 Elm St, Springfield', '555-1234', 'johndoe@example.com'),
('Jane Smith', '456 Maple St, Springfield', '555-5678', 'janesmith@example.com'),
('Robert Brown', '789 Oak St, Springfield', '555-8765', 'robertbrown@example.com'),
('Emily Johnson', '321 Pine St, Springfield', '555-4321', 'emilyjohnson@example.com'),
('Michael Davis', '654 Birch St, Springfield', '555-6789', 'michaeldavis@example.com'),
('Sarah Wilson', '987 Cedar St, Springfield', '555-2345', 'sarahwilson@example.com'),
('William Clark', '159 Spruce St, Springfield', '555-3456', 'williamclark@example.com'),
('Jessica Lee', '753 Ash St, Springfield', '555-4567', 'jessicalee@example.com'),
('Daniel Martinez', '852 Willow St, Springfield', '555-5670', 'danielmartinez@example.com'),
('Laura Taylor', '951 Poplar St, Springfield', '555-6781', 'laurataylor@example.com');

INSERT INTO DeliveryAgent (agent_name, contact_number, vehicle_type) VALUES
('James White', '555-1000', 'Motorbike'),
('Linda Green', '555-2000', 'Bicycle'),
('Charles Harris', '555-3000', 'Scooter'),
('Sophia Anderson', '555-4000', 'Motorbike'),
('Andrew Thompson', '555-5000', 'Car'),
('Natalie Lewis', '555-6000', 'Motorbike'),
('David Walker', '555-7000', 'Bicycle'),
('Emma Young', '555-8000', 'Car'),
('Joseph King', '555-9000', 'Scooter'),
('Olivia Scott', '555-0101', 'Motorbike');

-- Menu items for Restaurant 1 (Pizza Palace)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(1, 'Margherita Pizza', 'Classic cheese and tomato pizza', 8.99),
(1, 'Pepperoni Pizza', 'Pepperoni slices with mozzarella', 9.99),
(1, 'BBQ Chicken Pizza', 'Chicken, BBQ sauce, and onions', 10.99),
(1, 'Veggie Supreme', 'Mixed vegetables on tomato base', 8.49),
(1, 'Four Cheese Pizza', 'Mozzarella, parmesan, cheddar, gouda', 10.49),
(1, 'Hawaiian Pizza', 'Pineapple and ham', 9.49),
(1, 'Meat Feast Pizza', 'Pepperoni, ham, sausage, bacon', 11.99),
(1, 'Garlic Bread', 'Garlic bread with mozzarella', 5.99),
(1, 'Cheesy Sticks', 'Mozzarella sticks with marinara sauce', 6.49),
(1, 'Chocolate Lava Cake', 'Warm chocolate cake with lava center', 4.99);

-- Menu items for Restaurant 2 (Burger Barn)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(2, 'Classic Cheeseburger', 'Beef patty with cheese, lettuce, tomato', 7.99),
(2, 'Bacon Cheeseburger', 'Beef patty, bacon, cheese, BBQ sauce', 8.99),
(2, 'Veggie Burger', 'Vegetable patty with lettuce and tomato', 6.99),
(2, 'Chicken Burger', 'Grilled chicken with mayo and lettuce', 7.49),
(2, 'BBQ Burger', 'Beef patty with BBQ sauce and onion rings', 8.49),
(2, 'Double Cheeseburger', 'Double beef patty with cheese', 9.49),
(2, 'Mushroom Swiss Burger', 'Beef patty with mushrooms and Swiss cheese', 8.99),
(2, 'French Fries', 'Crispy fried potatoes', 3.49),
(2, 'Onion Rings', 'Crispy onion rings', 3.99),
(2, 'Milkshake', 'Vanilla, chocolate, or strawberry', 4.49);

-- Menu items for Restaurant 3 (Sushi Spot)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(3, 'California Roll', 'Crab, avocado, and cucumber', 8.99),
(3, 'Spicy Tuna Roll', 'Tuna with spicy mayo', 9.49),
(3, 'Salmon Nigiri', 'Rice topped with fresh salmon', 10.49),
(3, 'Shrimp Tempura Roll', 'Shrimp tempura with avocado', 9.99),
(3, 'Dragon Roll', 'Eel and cucumber topped with avocado', 11.49),
(3, 'Rainbow Roll', 'Assorted fish on California roll', 12.49),
(3, 'Miso Soup', 'Traditional Japanese soup', 3.99),
(3, 'Edamame', 'Steamed and salted soybeans', 4.49),
(3, 'Seaweed Salad', 'Salad with seaweed and sesame', 5.99),
(3, 'Green Tea Ice Cream', 'Japanese green tea flavored ice cream', 3.49);

-- Menu items for Restaurant 4 (Taco Town)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(4, 'Chicken Tacos', 'Soft tacos with grilled chicken', 6.99),
(4, 'Beef Tacos', 'Soft tacos with seasoned beef', 7.49),
(4, 'Fish Tacos', 'Soft tacos with crispy fish', 7.99),
(4, 'Carnitas Tacos', 'Soft tacos with slow-cooked pork', 8.49),
(4, 'Quesadilla', 'Cheese quesadilla with salsa', 5.99),
(4, 'Burrito', 'Large burrito with rice, beans, and meat', 9.49),
(4, 'Guacamole', 'Freshly made guacamole with chips', 4.99),
(4, 'Nachos', 'Tortilla chips with cheese and toppings', 6.49),
(4, 'Churros', 'Fried dough pastry with cinnamon sugar', 3.99),
(4, 'Horchata', 'Sweet rice drink with cinnamon', 2.99);

-- Menu items for Restaurant 5 (Pasta Paradise)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(5, 'Spaghetti Bolognese', 'Spaghetti with rich meat sauce', 10.49),
(5, 'Fettuccine Alfredo', 'Creamy Alfredo sauce with fettuccine', 9.99),
(5, 'Penne Arrabbiata', 'Penne pasta in spicy tomato sauce', 8.49),
(5, 'Lasagna', 'Layered pasta with meat and cheese', 11.99),
(5, 'Pesto Pasta', 'Pasta tossed in basil pesto sauce', 9.49),
(5, 'Garlic Bread', 'Toasted bread with garlic butter', 3.99),
(5, 'Caprese Salad', 'Tomato, mozzarella, and basil', 5.49),
(5, 'Tiramisu', 'Coffee-flavored Italian dessert', 5.99),
(5, 'Cannoli', 'Pastry filled with sweet ricotta', 4.49),
(5, 'Bruschetta', 'Toasted bread with tomato topping', 4.99);

-- Menu items for Restaurant 6 (Curry Corner)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(6, 'Butter Chicken', 'Creamy chicken curry', 11.49),
(6, 'Lamb Vindaloo', 'Spicy lamb curry', 12.49),
(6, 'Chana Masala', 'Chickpeas in spicy tomato sauce', 8.49),
(6, 'Paneer Tikka', 'Grilled paneer cubes with spices', 9.49),
(6, 'Aloo Gobi', 'Potato and cauliflower curry', 7.49),
(6, 'Garlic Naan', 'Naan bread with garlic', 2.99),
(6, 'Basmati Rice', 'Steamed aromatic rice', 2.49),
(6, 'Mango Lassi', 'Sweet mango yogurt drink', 3.49),
(6, 'Samosas', 'Fried pastry filled with spiced potatoes', 4.49),
(6, 'Gulab Jamun', 'Sweet milk dumplings in syrup', 3.99);

-- Menu items for Restaurant 7 (Steak House)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(7, 'Ribeye Steak', 'Juicy ribeye steak with herbs', 18.99),
(7, 'Filet Mignon', 'Tender beef filet', 24.99),
(7, 'T-Bone Steak', 'T-bone steak with seasoning', 21.99),
(7, 'Grilled Chicken Breast', 'Marinated grilled chicken', 12.99),
(7, 'Mashed Potatoes', 'Creamy mashed potatoes', 4.99),
(7, 'Caesar Salad', 'Romaine lettuce with Caesar dressing', 5.99),
(7, 'Baked Potato', 'Baked potato with toppings', 3.99),
(7, 'Garlic Shrimp', 'Garlic butter shrimp', 9.99),
(7, 'Creamed Spinach', 'Spinach with cream and garlic', 4.49),
(7, 'Cheesecake', 'Classic cheesecake dessert', 6.49);

-- Menu items for Restaurant 8 (Dragon Dine)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(8, 'General Tso\'s Chicken', 'Sweet and spicy chicken', 10.99),
(8, 'Kung Pao Chicken', 'Spicy stir-fried chicken with peanuts', 9.99),
(8, 'Sweet and Sour Pork', 'Pork with sweet and sour sauce', 10.49),
(8, 'Spring Rolls', 'Vegetable spring rolls', 5.49),
(8, 'Egg Drop Soup', 'Soup with egg strands', 4.49),
(8, 'Fried Rice', 'Rice with vegetables and soy sauce', 6.99),
(8, 'Lo Mein', 'Soft noodles with vegetables and meat', 8.99),
(8, 'Dumplings', 'Steamed or fried dumplings', 7.99),
(8, 'Moo Shu Pork', 'Pork with hoisin sauce and pancakes', 9.99),
(8, 'Fortune Cookies', 'Classic dessert cookies', 2.49);

-- Menu items for Restaurant 9 (Falafel Factory)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(9, 'Falafel Wrap', 'Falafel with vegetables in wrap', 7.49),
(9, 'Hummus Platter', 'Hummus with pita bread', 5.99),
(9, 'Shawarma', 'Thin-sliced marinated meat', 8.49),
(9, 'Baba Ganoush', 'Eggplant dip with pita', 6.49),
(9, 'Tabbouleh', 'Parsley salad with bulgur', 5.49),
(9, 'Stuffed Grape Leaves', 'Rice-stuffed grape leaves', 6.99),
(9, 'Kebabs', 'Grilled meat on skewers', 9.99),
(9, 'Baklava', 'Layered pastry with nuts and honey', 4.49),
(9, 'Lentil Soup', 'Warm soup with lentils', 3.99),
(9, 'Mint Lemonade', 'Refreshing minty lemonade', 2.99);

-- Menu items for Restaurant 10 (Greens & Grains)
INSERT INTO Menu (restaurant_id, item_name, item_description, price) VALUES
(10, 'Quinoa Salad', 'Salad with quinoa and veggies', 8.99),
(10, 'Avocado Toast', 'Toast with avocado and seeds', 6.99),
(10, 'Vegan Burger', 'Plant-based burger with lettuce', 9.49),
(10, 'Smoothie Bowl', 'Fruit smoothie with toppings', 7.49),
(10, 'Lentil Curry', 'Hearty lentil curry with rice', 8.49),
(10, 'Kale Chips', 'Crispy kale chips', 3.99),
(10, 'Roasted Veggies', 'Mixed roasted vegetables', 6.49),
(10, 'Chia Pudding', 'Chia seeds with almond milk', 4.49),
(10, 'Green Juice', 'Juice with greens and fruits', 5.49),
(10, 'Vegan Brownie', 'Brownie made without animal products', 3.99);

-- Inventory for Restaurant 1 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(1, 1, 50),  -- Margherita Pizza
(1, 2, 45),  -- Pepperoni Pizza
(1, 3, 40),  -- Veggie Pizza
(1, 4, 35),  -- BBQ Chicken Pizza
(1, 5, 30),  -- Hawaiian Pizza
(1, 6, 60),  -- Cheese Burger
(1, 7, 55),  -- Grilled Chicken Sandwich
(1, 8, 75),  -- Caesar Salad
(1, 9, 90),  -- French Fries
(1, 10, 80); -- Garlic Bread

-- Inventory for Restaurant 2 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(2, 11, 70),  -- Beef Burrito
(2, 12, 65),  -- Chicken Burrito
(2, 13, 60),  -- Tacos
(2, 14, 55),  -- Quesadilla
(2, 15, 50),  -- Nachos
(2, 16, 80),  -- Guacamole
(2, 17, 75),  -- Enchiladas
(2, 18, 65),  -- Chicken Fajitas
(2, 19, 60),  -- Steak Fajitas
(2, 20, 95);  -- Mexican Rice

-- Inventory for Restaurant 3 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(3, 21, 40),  -- Sushi Roll
(3, 22, 35),  -- Sashimi
(3, 23, 30),  -- Tempura
(3, 24, 25),  -- Udon Noodles
(3, 25, 20),  -- Teriyaki Chicken
(3, 26, 60),  -- Miso Soup
(3, 27, 55),  -- Edamame
(3, 28, 50),  -- Seaweed Salad
(3, 29, 45),  -- Rice Bowl
(3, 30, 70);  -- Green Tea

-- Inventory for Restaurant 4 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(4, 31, 80),  -- Pad Thai
(4, 32, 75),  -- Green Curry
(4, 33, 70),  -- Tom Yum Soup
(4, 34, 65),  -- Fried Rice
(4, 35, 60),  -- Thai Salad
(4, 36, 50),  -- Spring Rolls
(4, 37, 45),  -- Satay Chicken
(4, 38, 40),  -- Papaya Salad
(4, 39, 35),  -- Mango Sticky Rice
(4, 40, 90);  -- Coconut Soup

-- Inventory for Restaurant 5 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(5, 41, 50),  -- Spaghetti Carbonara
(5, 42, 45),  -- Lasagna
(5, 43, 40),  -- Risotto
(5, 44, 35),  -- Margherita Pizza
(5, 45, 30),  -- Tiramisu
(5, 46, 60),  -- Bruschetta
(5, 47, 55),  -- Caesar Salad
(5, 48, 70),  -- Panna Cotta
(5, 49, 80),  -- Gelato
(5, 50, 75);  -- Ravioli

-- Inventory for Restaurant 6 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(6, 51, 65),  -- Chicken Tikka
(6, 52, 60),  -- Butter Chicken
(6, 53, 55),  -- Biryani
(6, 54, 50),  -- Naan
(6, 55, 45),  -- Samosa
(6, 56, 40),  -- Paneer Tikka
(6, 57, 75),  -- Lamb Curry
(6, 58, 70),  -- Dal Makhani
(6, 59, 85),  -- Roti
(6, 60, 90);  -- Chai

-- Inventory for Restaurant 7 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(7, 61, 90),  -- Cheeseburger
(7, 62, 85),  -- Bacon Burger
(7, 63, 80),  -- Chicken Wings
(7, 64, 75),  -- Onion Rings
(7, 65, 70),  -- Hot Dog
(7, 66, 65),  -- Milkshake
(7, 67, 60),  -- French Fries
(7, 68, 55),  -- Coleslaw
(7, 69, 50),  -- Mac and Cheese
(7, 70, 95);  -- Ice Cream

-- Inventory for Restaurant 8 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(8, 71, 40),  -- Falafel
(8, 72, 35),  -- Hummus
(8, 73, 30),  -- Shawarma
(8, 74, 25),  -- Tabbouleh
(8, 75, 20),  -- Baba Ganoush
(8, 76, 60),  -- Pita Bread
(8, 77, 55),  -- Lentil Soup
(8, 78, 45),  -- Rice Pilaf
(8, 79, 50),  -- Stuffed Grape Leaves
(8, 80, 75);  -- Baklava

-- Inventory for Restaurant 9 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(9, 81, 65),  -- BBQ Ribs
(9, 82, 60),  -- Pulled Pork Sandwich
(9, 83, 55),  -- Brisket
(9, 84, 50),  -- Cornbread
(9, 85, 45),  -- Baked Beans
(9, 86, 70),  -- Coleslaw
(9, 87, 75),  -- Grilled Chicken
(9, 88, 80),  -- Mashed Potatoes
(9, 89, 90),  -- Apple Pie
(9, 90, 85);  -- Iced Tea

-- Inventory for Restaurant 10 Menu Items
INSERT INTO Inventory (restaurant_id, menu_id, stock_quantity) VALUES
(10, 91, 70),  -- Peking Duck
(10, 92, 65),  -- Kung Pao Chicken
(10, 93, 60),  -- Sweet and Sour Pork
(10, 94, 55),  -- Fried Rice
(10, 95, 50),  -- Egg Rolls
(10, 96, 75),  -- Wonton Soup
(10, 97, 80),  -- Spring Rolls
(10, 98, 90),  -- Dumplings
(10, 99, 85),  -- Hot and Sour Soup
(10, 100, 95);  -- Green Tea

UPDATE Inventory
SET stock_quantity = 50
WHERE restaurant_id = 1 AND menu_id = 1;

ALTER TABLE `Orders`
ADD COLUMN agent_id INT;

set SQL_SAFE_UPDATES = 0;

UPDATE `Orders`
SET agent_id = FLOOR(1 + (RAND() * 10));

ALTER TABLE `Orders`
ADD CONSTRAINT fk_agent_id
FOREIGN KEY (agent_id) REFERENCES DeliveryAgent(agent_id);





