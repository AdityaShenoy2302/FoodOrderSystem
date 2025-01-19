const express = require("express");
const bodyParser = require("body-parser");
const session = require("express-session");
const db = require("./db");
require("dotenv").config();

const app = express();
app.set("view engine", "ejs");
app.use(express.static("public"));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(
  session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
  })
);

// Routes
app.get("/", (req, res) => {
  res.render("login"); // Default page is login
});

app.get("/register", (req, res) => {
  res.render("register"); // Render registration form
});

app.post("/register", async (req, res) => {
  const { customer_name, address, contact_number, email } = req.body;

  try {
    // Check if email already exists
    const [existingUser] = await db.execute(
      "SELECT * FROM Customer WHERE email = ?",
      [email]
    );
    if (existingUser.length > 0) {
      return res.render("error", {
        message: "Email already registered. Please log in instead.",
      });
    }

    // Insert new user into the database
    await db.execute(
      "INSERT INTO Customer (customer_name, address, contact_number, email) VALUES (?, ?, ?, ?)",
      [customer_name, address, contact_number, email]
    );

    // Redirect to login after successful registration
    res.redirect("/");
  } catch (error) {
    console.error(error);
    res.render("error", { message: "Registration failed. Please try again." });
  }
});

app.post("/login", async (req, res) => {
  const { email } = req.body;

  // Check if user exists
  const [rows] = await db.execute("SELECT * FROM Customer WHERE email = ?", [
    email,
  ]);
  if (rows.length > 0) {
    req.session.customer_id = rows[0].customer_id; // Store customer ID in session
    res.redirect("/order");
  } else {
    res.render("error", { message: "User not found. Please register first." });
  }
});

app.get("/order", async (req, res) => {
  const customerId = req.session.customer_id;

  try {
    // Fetch restaurant names
    const [restaurants] = await db.execute(
      `SELECT restaurant_id, restaurant_name FROM Restaurant`
    );

    // Fetch menu items grouped by restaurant
    const [menuItems] = await db.execute(
      `SELECT menu_id, item_name AS item_name, restaurant_id 
       FROM Menu`
    );

    res.render("order", {
      customerId,
      restaurants,
      menuItems,
    });
  } catch (error) {
    console.error(error);
    res.render("error", { message: "Failed to load data for ordering." });
  }
});

app.post("/order", async (req, res) => {
  const { restaurant_id, item_id, quantity } = req.body;
  const customer_id = req.session.customer_id;

  try {
    // Insert order into database
    // Generate a random agent_id between 1 and 10
    const agent_id = Math.floor(Math.random() * 10) + 1;

    const [orderResult] = await db.execute(
      `INSERT INTO \`Orders\` (customer_id, restaurant_id, total_amount, order_status, agent_id) 
   VALUES (?, ?, (SELECT price * ? FROM Menu WHERE menu_id = ?), 'Pending', ?)`,
      [customer_id, restaurant_id, quantity, item_id, agent_id]
    );

    const orderId = orderResult.insertId;
    req.session.order_id = orderId; // Store order ID in session for payment

    await db.execute(
      `INSERT INTO OrderItem (order_id, menu_id, quantity, price)
       VALUES (?, ?, ?, (SELECT price FROM Menu WHERE menu_id = ?))`,
      [orderId, item_id, quantity, item_id]
    );

    res.redirect("/payment");
  } catch (error) {
    console.error(error);
    res.render("error", { message: error.message });
  }
});

app.get("/payment", async (req, res) => {
  const orderId = req.session.order_id;

  try {
    // Fetch the total price
    const [rows] = await db.execute(
      `SELECT SUM(price * quantity) AS totalPrice 
       FROM OrderItem 
       WHERE order_id = ?`,
      [orderId]
    );

    let totalPrice = 0;
    if (rows.length > 0 && rows[0].totalPrice !== null) {
      totalPrice = rows[0].totalPrice;
    }

    // Ensure totalPrice is a valid number
    totalPrice = parseFloat(totalPrice); // Force conversion to float

    // Check if totalPrice is a valid number
    if (isNaN(totalPrice)) {
      totalPrice = 0; // Default to 0 if it's not a valid number
    }

    res.render("payment", { totalPrice });
  } catch (error) {
    console.error("Error fetching total price:", error);
    res.render("error", { message: "Error fetching total price." });
  }
});

app.post("/payment", async (req, res) => {
  const { paymentMethod, cardNumber, expiryDate, cvv } = req.body;
  const orderId = req.session.order_id;

  // Basic validation for payment details
  if (!cardNumber || cardNumber.length !== 16 || !/^\d+$/.test(cardNumber)) {
    return res.render("error", {
      message: "Invalid card number. Please enter a 16-digit number.",
    });
  }
  if (!cvv || cvv.length !== 3 || !/^\d+$/.test(cvv)) {
    return res.render("error", {
      message: "Invalid CVV. Please enter a 3-digit CVV.",
    });
  }

  // Simulate payment processing
  try {
    console.log(`Processing payment for Order ID: ${orderId}`);
    console.log(`Payment Method: ${paymentMethod}`);
    console.log(`Card Number: **** **** **** ${cardNumber.slice(-4)}`);
    console.log(`Expiry Date: ${expiryDate}`);

    // Simulated delay to mimic payment processing
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Assuming payment was successful, update order status to 'Confirmed'
    await db.execute(
      `UPDATE \`Orders\` SET order_status = 'Confirmed' WHERE order_id = ?`,
      [orderId]
    );

    res.redirect("/confirmation");
  } catch (error) {
    console.error(error);
    res.render("error", {
      message: "Payment processing failed. Please try again.",
    });
  }
});

// Assuming the delivery agent is assigned to an order
app.get("/confirmation", async (req, res) => {
  const orderId = req.session.order_id;

  try {
    // Query to get the delivery agent's details for the order
    const [deliveryAgent] = await db.execute(
      `SELECT da.agent_name, da.contact_number 
       FROM DeliveryAgent da
       JOIN \`Orders\` o ON o.agent_id = da.agent_id
       WHERE o.order_id = ?`,
      [orderId]
    );

    if (deliveryAgent.length > 0) {
      const agent = deliveryAgent[0];
      res.render("confirmation", {
        orderId: orderId,
        deliveryAgentName: agent.agent_name,
        contactNumber: agent.contact_number,
      });
    } else {
      res.render("confirmation", {
        orderId: orderId,
        deliveryAgentName: "Not Assigned",
        contactNumber: "N/A",
      });
    }
  } catch (error) {
    console.error(error);
    res.render("error", {
      message: "Error retrieving delivery agent information.",
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
