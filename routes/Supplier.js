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

    // search suppliers
    router.get('/search', async (req, res) => {
        const { query } = req.query; //
        console.log('I am hit', query)
        // stored procedure get suppliers 
        let result = await db.query(`
            exec GETSUPPLIERS '${query}'
        `)
        res.json(result.recordset);
    });

    // @route   /api/supplier
    // @desc    Get all suppliers
    // @access  Public
    router.get('/', async (req, res) => {
        let result = await db.query('SELECT * FROM Contact WHERE type = \'supplier\'');
        console.log("I am hit", result.recordset)
        res.json(result.recordset);
    });

    // get supplier by id
    router.get('/:id', async (req, res) => {
        const { id } = req.params;
        let result = await db.query(`SELECT * FROM Contact WHERE ID = ${id}`);
        res.json(result.recordset[0]);
    });

    // create new supplier
    router.post('/', async (req, res) => {
        let data = {
            name: req.body.name,
            email: req.body.email,
            phone: req.body.phone,
            address: req.body.address,
            type: 'supplier',
        }

        // calculate id for new supplier
        let result_max = await db.query(`SELECT MAX(ID) AS max FROM Contact`);
        let id = result_max.recordset[0].max + 1;

        // insert new supplier
        let result = await db.query(`INSERT INTO Contact (ID, Name, Email, Phone, Address, Type) VALUES (${id}, \'${data.name}\', \'${data.email}\', \'${data.phone}\', \'${data.address}\', \'${data.type}\')`);

        res.json(result.recordset);
    });

    // get all products of a supplier
    router.get('/products/:id', async (req, res) => {
        let result = await db.request()
            .input('supplier_id', db.Int, req.params.id)
            .execute('GetProductsBySupplier')
        res.json(result);
    })


    // add a purchase order
    router.post('/purchase', async (req, res) => {

        let data = {
            type: 'purchase',
            contact_id: req.body.contact_id,
            invoice_no: req.body.invoice_no,
            transaction_date: new Date().toISOString(),
            final_total: req.body.final_total,
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

            // create the transaction
            let result = await db.query(`INSERT INTO [dbo].[Transaction] (
                ID, Type, Contact_ID, Invoice_No, Transaction_Date, 
                Final_Total,updated_at) VALUES (
                    ${id}, '${data.type}', ${data.contact_id}, '${data.invoice_no}', '${data.transaction_date}', 
                    ${data.final_total},
                    GETDATE()
                    )`
            );
            // create purchase lines
            result_max = await db.query(`SELECT MAX(ID) AS max FROM PurchaseLines`);
            let purchase_line_id = result_max.recordset[0].max + 1;
            for (let i = 0; i < req.body.variations.length; i++) {
                let result = await db.query(`INSERT INTO PurchaseLines (ID,
                Transaction_ID, Variation_ID, Quantity, Purchase_Price) VALUES (
                   ${purchase_line_id} ,${id}, ${req.body.variations[i].id}, ${req.body.variations[i].quantity},
                    ${req.body.variations[i].purchase_price})`
                );
                purchase_line_id++;
            }
            // update the quantity
            for (let i = 0; i < req.body.variations.length; i++) {
                let result = await db.query(`UPDATE ProductVariation SET Quantity = QUANTITY + ${req.body.variations[i].quantity}
                WHERE ID = ${req.body.variations[i].id}`
                );
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

    // update supplier
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
        res.json({ message: "Supplier updated" }, 200);
    });

    // get all purchases from a supplier
    router.get('/purchases/:id', async (req, res) => {
        const { id } = req.params;
        let result = await db.query(`SELECT * FROM [Transaction] t WHERE t.Contact_ID = ${id} AND t.Type = 'purchase'`);
        // get the total amount of purchases
        let total_purchases = await db.query(
            `Select COUNT (*) as purchases, SUM(final_total) as totalPurchases from [Transaction] t1
            WHERE t1.Contact_ID =${id} AND t1.Type = 'purchase'`);
        console.log(total_purchases);
        res.json({
            result: result.recordset,
            purchases: total_purchases.recordset[0].purchases,
            purchasesAmount: total_purchases.recordset[0].totalPurchases
        });
    });



    return router;
}
