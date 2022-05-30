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


    // here we define the routes for the authentication
    // @route   /api/login
    // @desc    Login a User
    // @access  Public
    router.post("/login", async (req, res) => {
        // Form validation
        const { errors, isValid } = validator.validateLoginInput(req.body);
        // Check validation
        if (!isValid) {
            return res.status(400).json(errors);
        }
        const email = req.body.email;
        const password = req.body.password;
        // get user info from db
        let user = await db.query(
            `SELECT u.*,r.name as role FROM [User] u inner join Role r on r.id =u.role_id  WHERE u.email='${email}'`,
        )
        // // Find user by email
        if (user.recordset.length === 0) {
            return res.status(404).json({ message: "Email not found" });
        }
        user = (user.recordset[0]);

        // Check password
        bcrypt.compare(password, user.password).then(async (isMatch) => {
            if (isMatch) {
                // user matched
                // Create JWT Payload
                const payload = {
                    id: user.id,
                    name: user.name,
                };
                // delete password from user
                delete user.password;
                // get associated permissions
                let permissions = await db.query(
                    `Select p.* from Permission p inner join RolePermission rp on rp.permission_id = p.id where rp.role_id = ${user.role_id}`,
                )
                console.log(permissions)
                user.permissions = permissions.recordset;
                // Sign token
                jwt.sign(
                    payload,
                    keys.secretOrKey,
                    {
                        expiresIn: 31556926, // 1 year in seconds
                    },
                    (err, token) => {
                        res.json({
                            success: true,
                            token: "Bearer " + token,
                            user,
                        });
                    }
                );
            } else {
                return res.status(400).json({ message: "Password incorrect" });
            }
        });
    });

    return router;
}
