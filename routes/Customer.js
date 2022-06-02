const express = require("express");
const router = express.Router();
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const path = require("path");

const validator = require("../validation/Auth");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const keys = require("../config/keys");

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, "images");
    },
    filename: function (req, file, cb) {
        cb(null, uuidv4() + "-" + Date.now() + path.extname(file.originalname));
    },
});

const fileFilter = (req, file, cb) => {
    const allowedFileTypes = ["image/jpeg", "image/jpg", "image/png"];
    if (allowedFileTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(null, false);
    }
};

let upload = multer({
    storage,
    fileFilter,
    limits: { fieldSize: 1024 * 1024 * 25 },
});

module.exports = (db) => {

    // search customers
    router.get('/search', async (req, res) => {
        const { query } = req.query; //
        console.log('I am hit', query)
        // stored procedure get customers 
        let result = await db.query(`
            exec GETCUSTOMERS '${query}'
        `)
        res.json(result.recordset);
    });
    // get customers
    router.get('/', async (req, res) => {
        console.log("get customers");
        let result = await db.query('SELECT * FROM Contact WHERE type = \'customer\'');
        console.log(result);
        res.json(result.recordset);
    });

    // get customer by id
    router.get('/:id', async (req, res) => {
        const { id } = req.params;
        let result = await db.query(`SELECT * FROM Contact WHERE ID = ${id}`);
        res.json(result.recordset[0]);
    });

    // create new customer
    router.post('/', async (req, res) => {
        let data = {
            name: req.body.name,
            email: req.body.email,
            phone: req.body.phone,
            address: req.body.address,
            type: 'customer',
        }

        // calculate id for new customer
        let result_max = await db.query(`SELECT MAX(ID) AS max FROM Contact`);
        let id = result_max.recordset[0].max + 1;

        // insert new customer
        let result = await db.query(`INSERT INTO Contact (ID, Name, Email, Phone, Address, Type) VALUES (${id}, \'${data.name}\', \'${data.email}\', \'${data.phone}\', \'${data.address}\', \'${data.type}\')`);

        res.json(result.recordset);
    });


    // update customer
    router.put('/:id', async (req, res) => {
        const { id } = req.params;
        console.log("I am hit")
        let data = {
            name: req.body.name,
            email: req.body.email,
            phone: req.body.phone,
            address: req.body.address,
        }
        let result = await db.query(`UPDATE Contact SET Name = \'${data.name}\', Email = \'${data.email}\', Phone = \'${data.phone}\', Address = \'${data.address}\' WHERE ID = ${id}`);
        res.json({ message: "Customer updated" }, 200);
    });


    // add a sale
    router.post('/sale', async (req, res) => {

        let data = {
            type: 'sell',
            contact_id: req.body.contact_id,
            invoice_no: req.body.invoice_no,
            transaction_date: new Date().toISOString(),
            final_total: req.body.final_total,
            discount_id: req.body.discount_id,
            discount_amount: req.body.discount_amount,
        }
        console.log(req.body);
        // return;

        // start a db transaction
        let transaction = new db.Transaction();
        await transaction.begin()
        // get id for new transaction
        try {
            let result_max = await db.query(`SELECT MAX(ID) AS max FROM [Transaction]`);
            let id = result_max.recordset[0].max + 1;
            // generate a new invoice number
            let invoice_no = await db.query(`SELECT MAX(id) AS max FROM [Transaction] where type = 'sell'`);
            let invoice_no_id = invoice_no.recordset[0].max + 1;
            let invoice_no_new = "INV-SELL-" + invoice_no_id;
            data.invoice_no = invoice_no_new;
            // create the transaction
            let result = await db.query(`INSERT INTO [dbo].[Transaction] (
                ID, Type, Contact_ID, Invoice_No, Transaction_Date, 
                Final_Total,updated_at,discount_id,discount_amount) VALUES (
                    ${id}, '${data.type}', ${data.contact_id}, '${data.invoice_no}', '${data.transaction_date}', 
                    ${data.final_total},
                    GETDATE(),
                    ${data.discount_id === 0 ? 'NULL' : data.discount_id},
                    ${data.discount_id === 0 ? 'NULL' : data.discount_amount}
                    )`
            );
            // create sell lines
            result_max = await db.query(`SELECT MAX(ID) AS max FROM SellLines`);
            let sell_line_id = result_max.recordset[0].max + 1;

            for (let i = 0; i < req.body.variations.length; i++) {
                let result = await db.query(`INSERT INTO SellLines (ID,
                Transaction_ID, Variation_ID,Product_ID ,Quantity, Sell_Price) VALUES (
                   ${sell_line_id} ,${id}, ${req.body.variations[i].id},
                    ${req.body.variations[i].product_id},
                   ${req.body.variations[i].quantity},
                    ${req.body.variations[i].sell_price})`
                );
                sell_line_id++;
            }

            // update the quantity
            for (let i = 0; i < req.body.variations.length; i++) {
                let result = await db.query(`UPDATE ProductVariation SET Quantity = Quantity - ${req.body.variations[i].quantity} WHERE ID = ${req.body.variations[i].id}`);
            }
            // commit the transaction
            await transaction.commit();
        } catch (err) {
            await transaction.rollback();
            console.log(err);
            res.status(400).json({
                message: err.message
            });
        }
        res.json({
            message: 'success'
        });

    })

    // get all purchases of a customer
    router.get('/purchases/:id', async (req, res) => {
        const { id } = req.params;
        let result = await db.query(`SELECT * FROM [Transaction] t WHERE t.Contact_ID = ${id} AND t.Type = 'sell'`);
        // get the total amount of purchases
        let total_purchases = await db.query(
            `Select COUNT (*) as purchases, SUM(final_total) as totalPurchases from [Transaction] t1
            WHERE t1.Contact_ID =${id} AND t1.Type = 'sell'`);
        console.log(total_purchases);
        res.json({
            result: result.recordset,
            purchases: total_purchases.recordset[0].purchases,
            purchasesAmount: total_purchases.recordset[0].totalPurchases
        });
    });

    return router;
}
