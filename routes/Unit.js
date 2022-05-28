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

    // @route   /api/unit
    // @desc    Get all units
    // @access  Public
    router.get("/", async (req, res) => {
        let units = await db.query(
            `SELECT * FROM [Unit]`,
        )
        res.json(units.recordset);
    });

    // @route   /api/unit/:id
    // @desc    Get a unit by id
    // @access  Public
    router.get("/:id", async (req, res) => {
        let unit = await db.query(
            `SELECT * FROM [Unit] WHERE id=${req.params.id}`,
        )
        res.json(unit.recordset);
    });


    // @route   /api/unit
    // @desc    Create a unit
    // @access  Private
    router.post("/", async (req, res) => {
        let unit = {
            name: req.body.name,
        }
        console.log(unit);
        // generate new id for the unit
        let newId = await db.query(
            `SELECT MAX(id) as CO FROM [Unit]`,
        )
        console.log(newId);
        newId = newId.recordset[0].CO + 1;
        unit.id = newId;
        // insert unit into db
        let result = await db.query(
            `INSERT INTO [Unit] VALUES (${newId}, '${unit.name}')`,
        )
        res.json(result);
    });

    // @route   /api/unit/:id
    // @desc    Update a unit
    // @access  Private
    router.put("/:id", async (req, res) => {
        let unit = {
            name: req.body.name,
        }
        console.log(unit);
        // update unit into db
        let result = await db.query(
            `UPDATE [Unit] SET name='${unit.name}' WHERE id=${req.params.id}`,
        )
        res.json(result);
    });

    // @route   /api/unit/:id
    // @desc    Delete a unit
    // @access  Private
    router.delete("/:id", async (req, res) => {
        // delete unit from db
        let result = await db.query(
            `DELETE FROM [Unit] WHERE id=${req.params.id}`,
        )
        res.json(result);
    });

    return router;
}
