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

    // @route   /api/role
    // @desc    Get all users
    // @access  Public
    router.get("/", async (req, res) => {
        let users = await db.query(
            `SELECT u.*,r.name as role from [User] u inner join [Role] r on u.role_id=r.id`,
        )
        let result = users.recordset;
        console.log(users.recordset);
        // get associated permissions
        for (let i = 0; i < result.length; i++) {
            let permissions = await db.query(
                `Select p.* from Permission p inner join RolePermission rp on rp.permission_id = p.id where rp.role_id = ${result[i].role_id}`,
            )
            console.log(permissions);
            result[i].permissions = permissions.recordset;
        }
        return res.json(result);
    });

    // get a user
    // @route   /api/user/:id
    // @desc    Get a user
    // @access  Public
    router.get("/:id", async (req, res) => {
        let user = await db.query(
            `SELECT u.*,r.name as role from [User] u inner join [Role] r on u.role_id=r.id where u.id=${req.params.id}`,
        )
        let result = user.recordset[0];
        return res.json(result);
    });

    // add user
    // @route   /api/user
    // @desc    Add a user
    // @access  Public
    router.post("/", async (req, res) => {
        let user = req.body;
        console.log(user)
        // Hash password before saving in database
        bcrypt.genSalt(10, (err, salt) => {
            bcrypt.hash(user.password, salt, async (err, hash) => {
                if (err) throw err;
                user.password = hash;
                // generate a new id for the user
                user.id = await db.query(`SELECT MAX(id) as id FROM [User]`);
                user.id = user.id.recordset[0].id + 1;
                // add user to db
                let q = `INSERT INTO [User] (id,username,email,password,role_id,firstname,lastname) 
                VALUES (${user.id},'${user.username}','${user.email}','${user.password}',${user.role},'${user.first_name}','${user.last_name}')`
                console.log(q)
                let result = await db.query(
                    q
                )
                return res.json(result);
            });
        });
    });

    // update user
    // @route   /api/user/:id
    // @desc    Update a user
    // @access  Public
    router.put("/:id", async (req, res) => {
        let user = req.body;
        console.log(user)
        // Hash password before saving in database
        // if there is a new password
        if (user.password) {
            console.log("I am executed")
            bcrypt.genSalt(10, async (err, salt) => {
                user.password = await bcrypt.hash(user.password, salt)
                let q = `UPDATE [User] SET username='${user.username}',
                email='${user.email}',
                ${user.password ? `password='${user.password}',` : ""}
                role_id=${user.role},
                firstname='${user.first_name}',
                lastname='${user.last_name}' WHERE id=${req.params.id}`
                console.log(q)
                let result = await db.query(
                    q
                )
                return res.json(result);
            });
        }
        else {
            let q = `UPDATE [User] SET username='${user.username}',
            email='${user.email}',
            role_id=${user.role},
            firstname='${user.first_name}',
            lastname='${user.last_name}' WHERE id=${req.params.id}`
            console.log(q)
            let result = await db.query(
                q
            )
            return res.json(result);
        }

    });



    return router;
}
