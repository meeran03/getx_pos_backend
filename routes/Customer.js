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

    // get top buyer customers
    router.get('/top-customers', async (req, res) => {
        let result = await db.query(`Select * from GetTopBuyerCustomers`)
        res.json(result);
    })


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
    return router;
}
