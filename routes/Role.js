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
    // @desc    Get all categories
    // @access  Public
    router.get("/", async (req, res) => {
        let roles = await db.query(
            `SELECT * from [Role]`,
        )
        let result = roles.recordset;
        console.log(roles.recordset);
        // get permissions per role
        for (let i = 0; i < result.length; i++) {
            let permissions = await db.query(
                `SELECT p.name,p.id from [RolePermission] r join Permission p on p.id=r.permission_id where [role_id]=${result[i].id} `,
            )
            console.log(permissions);
            result[i].permissions = permissions.recordset;
        }
        res.json(result);
    });

    // @route   /api/role/:id
    // @desc    Get a role by id
    // @access  Public
    router.get("/:id", async (req, res) => {
        let role = await db.query(
            `SELECT r.*, p.name as permission_name,p.id as permission_id FROM [Role] r left join RolePermission rp on r.id = rp.role_Id left join Permission p on rp.permission_Id = p.id WHERE id=${req.params.id}`,
        )
        res.json(role.recordset);
    });


    // @route   /api/role
    // @desc    Create a role
    // @access  Private
    router.post("/", async (req, res) => {
        let role = {
            name: req.body.name,
        }
        console.log(role);
        // generate new id for the role
        let newId = await db.query(
            `SELECT MAX(id) as CO FROM [Role]`,
        )
        newId = newId.recordset[0].CO + 1;
        role.id = newId;
        console.log(newId);
        let result = await db.query(
            `INSERT INTO [Role] VALUES (${newId}, '${role.name}','${(new Date()).toISOString().slice(0, 19).replace('T', ' ')}')`,
        )
        // generate relevant rolepermissions
        let permissions = req.body.permissions
        console.log(permissions)
        // get role_permission_id for next insert
        let role_permission_id = await db.query(
            `SELECT MAX(id) as CO FROM [RolePermission]`,
        )
        role_permission_id = role_permission_id.recordset[0].CO + 1;
        console.log(role_permission_id);
        for (let i = 0; i < permissions.length; i++) {

            let result = await db.query(
                `INSERT INTO [RolePermission] VALUES (${role_permission_id},${newId}, ${permissions[i]})`,
            )
            role_permission_id++;
        }
        res.json(result);
    });

    // @route   /api/role/:id
    // @desc    Update a role
    // @access  Private
    router.put("/:id", async (req, res) => {
        let role = {
            name: req.body.name,
        }
        console.log(role);
        // update role into db
        let result = await db.query(
            `UPDATE [Role] SET name='${role.name}' WHERE id=${req.params.id}`,
        )

        // update corresponding permissions
        let permissions = req.body.permissions
        // delete all permissions for this role
        let result2 = await db.query(
            `DELETE FROM [RolePermission] WHERE role_Id=${req.params.id}`,
        )
        // add new permissions
        let role_permission_id = await db.query(
            `SELECT MAX(id) as CO FROM [RolePermission]`,
        )
        role_permission_id = role_permission_id.recordset[0].CO + 1;
        console.log(role_permission_id);
        for (let i = 0; i < permissions.length; i++) {

            let result = await db.query(
                `INSERT INTO [RolePermission] VALUES (${role_permission_id},${req.params.id}, ${permissions[i]})`,
            )
            role_permission_id++;
        }
        res.json(result);
    });

    // @route   /api/role/:id
    // @desc    Delete a role
    // @access  Private
    router.delete("/:id", async (req, res) => {
        // delete role from db
        let result = await db.query(
            `DELETE FROM [Role] WHERE id=${req.params.id}`,
        )
        res.json(result);
    });

    return router;
}
