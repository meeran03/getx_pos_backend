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

    // @route   /api/category
    // @desc    Get all categories
    // @access  Public
    router.get("/", async (req, res) => {
        let categories = await db.query(
            `SELECT * FROM [Category]`,
        )
        res.json(categories.recordset);
    });

    // @route   /api/category/:id
    // @desc    Get a category by id
    // @access  Public
    router.get("/:id", async (req, res) => {
        let category = await db.query(
            `SELECT * FROM [Category] WHERE id=${req.params.id}`,
        )
        res.json(category.recordset);
    });


    // @route   /api/category
    // @desc    Create a category
    // @access  Private
    router.post("/", async (req, res) => {
        let category = {
            name: req.body.name,
        }
        console.log(category);
        // generate new id for the category
        let newId = await db.query(
            `SELECT MAX(id) as CO FROM [Category]`,
        )
        console.log(newId);
        newId = newId.recordset[0].CO + 1;
        category.id = newId;
        // insert category into db
        let result = await db.query(
            `INSERT INTO [Category] VALUES (${newId}, '${category.name}')`,
        )
        res.json(result);
    });

    // @route   /api/category/:id
    // @desc    Update a category
    // @access  Private
    router.put("/:id", async (req, res) => {
        let category = {
            name: req.body.name,
        }
        console.log(category);
        // update category into db
        let result = await db.query(
            `UPDATE [Category] SET name='${category.name}' WHERE id=${req.params.id}`,
        )
        res.json(result);
    });

    // @route   /api/category/:id
    // @desc    Delete a category
    // @access  Private
    router.delete("/:id", async (req, res) => {
        // delete category from db
        let result = await db.query(
            `DELETE FROM [Category] WHERE id=${req.params.id}`,
        )
        res.json(result);
    });

    return router;
}
