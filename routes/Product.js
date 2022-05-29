const express = require("express");
const router = express.Router();
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const path = require("path");

const validator = require("../validation/Auth");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const keys = require("../config/keys");
const config = require("../config/keys");

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

    // @route   /api/product/best-selling
    // @desc    Get the best selling products
    // @access  Public
    router.get("/best-selling", async (req, res) => {
        let products = await db.query(
            `EXEC [GetBestSellingProductVariations]`
        )
        // append the product image
        products = products.recordset;
        for (let i = 0; i < products.length; i++) {
            products[i].image = `${config.image_url + products[i].image}`;
        }
        res.json(products);
    });

    // @route   /api/product/out-of-stock
    // @desc    Get the out of stock products
    // @access  Public
    router.get("/out-of-stock", async (req, res) => {
        let products = await db.query(
            `Select * from [OutOfStockProducts]`
        )
        res.json(products.recordset);
    });

    // @route   /api/product
    // @desc    Search products
    // @access  Public
    router.get("/search", async (req, res) => {
        // call stored procedure with parameters
        let products = await db.query(
            `exec [GetSimilarProducts] '${req.query.search}'`
        )
        res.json(products.recordset);

        // let result = await db.request()
        //     .input('query', db.VarChar, req.query)
        //     .execute('GetSimilarProducts')
        // res.json(result.recordset);
    });

    // @route   /api/product/category/:id
    // @desc    Get all products of a category
    // @access  Public
    router.get("/category/:id", async (req, res) => {
        let products = await db.request()
            .input('category_id', db.Int, req.params.id)
            .execute('GetProductsByCategory')
        res.json(products.recordset);
    });


    // get all products
    router.get("/", async (req, res) => {
        let products = await db.query(
            `SELECT p.*,c.name as category,u.name as unit FROM [Product] p inner join category c on p.category_id = c.id inner join Unit u on u.id = p.unit_id`,
        )
        let result = products.recordset;
        // append image url
        for (let i = 0; i < result.length; i++) {
            result[i].image = `http://localhost:5001/images/${result[i].image}`;
        }
        res.json(result);
    });

    // get single product
    router.get("/:id", async (req, res) => {
        let product = await db.query(
            `SELECT p.*,c.name as category,u.name as unit FROM [Product] p inner join category c on p.category_id = c.id inner join Unit u on u.id = p.unit_id where p.id = ${req.params.id}`,
        )
        let result = product.recordset;
        // append image url
        result[0].image = `http://localhost:5001/images/${result[0].image}`;
        // get variations associated with the product
        let variations = await db.query(
            `SELECT * FROM [ProductVariation] where product_id = ${req.params.id}`,
        )
        result[0].variations = variations.recordset;
        res.json(result[0]);
    });

    // add product
    router.post("/", upload.single("image"), async (req, res) => {
        let data = {
            name: req.body.name,
            description: req.body.description,
            category_id: req.body.category_id,
            image: req.file.filename,
            type: req.body.type,
            unit_id: req.body.unit_id,
        };

        // generate new id for the product
        let newId = await db.query(
            `SELECT MAX(id) as id FROM [Product]`
        )
        newId = newId.recordset[0].id + 1;
        data.id = newId;

        // start a db transaction
        let transaction = new db.Transaction();
        await transaction.begin()
        try {
            // insert product
            let result = await db.query(
                `INSERT INTO [Product] (id,name,description,category_id,image,type,unit_id) VALUES (${newId},'${data.name}','${data.description}',${data.category_id},'${data.image}','${data.type}','${data.unit_id}')`
            )
            // generate product variations
            let variations = JSON.parse(req.body.variations);
            for (let i = 0; i < variations.length; i++) {
                let variation = variations[i];
                let id = await db.query(
                    `SELECT MAX(id) as id FROM [ProductVariation]`
                )
                id = id.recordset[0].id + 1;
                variation.id = id;
                variation.product_id = id;
                const q = `INSERT INTO [ProductVariation] (id,product_id,name,default_sell_price,sku,created_at,updated_at,quantity) VALUES (
                    ${id},
                    ${newId},
                    '${variation.name}',
                    ${variation.default_selling_price},
                    '${variation.sku}',
                    '${new Date().toISOString()}',
                    '${new Date().toISOString()}',
                    0
                    )`
                await db.query(
                    q
                )

            }
            // commit the transaction
            await transaction.commit();
            res.json(data);
        } catch (err) {
            // rollback the transaction
            console.log(err)
            await transaction.rollback();
            res.status(400).json(err);

        }
    })

    // delete product variation
    router.delete("/:id", async (req, res) => {
        let result = await db.query(
            `DELETE FROM [ProductVariation] where id = ${req.params.id}`
        )
        res.json(result.recordset);
    });

    // update product variation
    router.put("/variation/:id", async (req, res) => {
        let data = {
            name: req.body.name,
            default_sell_price: req.body.default_sell_price,
            sku: req.body.sku,
        }
        let result = await db.query(
            `UPDATE [ProductVariation] SET name = '${data.name}', default_sell_price = ${data.default_sell_price}, sku = '${data.sku}' where id = ${req.params.id}`
        )
        res.json(result.recordset);
    });


    // add product variation
    router.post("/variation", async (req, res) => {
        let data = {
            name: req.body.name,
            default_sell_price: req.body.default_sell_price,
            sku: req.body.sku,
            product_id: req.body.product_id,
        }
        let id = await db.query(
            `SELECT MAX(id) as id FROM [ProductVariation]`
        )
        id = id.recordset[0].id + 1;
        data.id = id;
        const q = `INSERT INTO [ProductVariation] (id,product_id,name,default_sell_price,sku,created_at,updated_at,quantity) VALUES (
            ${id},
            ${data.product_id},
            '${data.name}',
            ${data.default_sell_price},
            '${data.sku}',
            '${new Date().toISOString()}',
            '${new Date().toISOString()}',
            0
            )`
        let result = await db.query(
            q
        )
        res.json(result.recordset);
    });

    // update product
    router.put("/:id", upload.single("image"), async (req, res) => {
        let data = {
            name: req.body.name,
            description: req.body.description,
            category_id: req.body.category_id,
            type: req.body.type,
            unit_id: req.body.unit_id,
        };
        if (req.file) {
            data.image = req.file.filename;
        }
        let result = await db.query(
            `UPDATE [Product] SET name = '${data.name}', 
                description = '${data.description}', 
                category_id = ${data.category_id}, 
                ${req.file ? `image = '${data.image}', ` : ''} 
                type = '${data.type}', 
                unit_id = '${data.unit_id}' 
            where id = ${req.params.id}`
        )
        res.json(result.recordset);
    });


    // search product variations
    router.get("/variation/search", async (req, res) => {
        const { query } = req.query;
        console.log(query)
        let result = await db.query(
            `EXEC SEARCHVARIATIONS '${query}'`
        )
        // append the image path to the result
        for (let i = 0; i < result.recordset.length; i++) {
            result.recordset[i].image = `${config.image_url}/${result.recordset[i].image}`;
        }
        res.json(result.recordset);
    });

    return router;
}
