const express = require("express");
const cors = require("cors");
const mssql = require("mssql/msnodesqlv8");
const bodyParser = require("body-parser");

const app = new express();

app.use(express.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cors());
app.use("/images", express.static("images"));
app.use(express.static("public"));

const port = process.env.PORT || 5001;

const server = app.listen(port, () => {
    console.log("Server running at Port ", port);
});

// establish connection to mssql using connection string
const db = require("./config/keys");
mssql.connect(
    db,
    (err) => {
        if (err) {
            console.log(err);
        } else {
            console.log("Connected to database");
        }
    }
)

// here we import our routes
const authRoutes = require("./routes/Auth")(mssql);
const categories = require("./routes/Category")(mssql);
const products = require("./routes/Product")(mssql);
const units = require("./routes/Unit")(mssql);
const customers = require("./routes/Customer")(mssql);
const suppliers = require("./routes/Supplier")(mssql);
const roles = require("./routes/Role")(mssql);
const permissions = require("./routes/Permission")(mssql);
const discounts = require("./routes/Discount")(mssql);
const purchases = require("./routes/Purchase")(mssql);
const sales = require("./routes/Sale")(mssql);
const statistics = require("./routes/Statistics")(mssql);
const users = require("./routes/User")(mssql);

// here we define our url routes
app.use("/api/auth", authRoutes);
app.use("/api/category", categories);
app.use("/api/product", products);
app.use("/api/unit", units);
app.use("/api/user", users);
app.use("/api/customer", customers);
app.use("/api/supplier", suppliers)
app.use("/api/role", roles);
app.use("/api/permission", permissions);
app.use("/api/discount", discounts);
app.use("/api/purchases", purchases);
app.use("/api/sales", sales);
app.use("/api/statistics", statistics);