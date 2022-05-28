// configuration for mssql connector
const config = {
    connectionString: `Driver=SQL Server;Server=.\\SQLEXPRESS;Database=Getx;Trusted_Connection=True;`,
    secretOrKey: "secret",
    image_url: "http://localhost:5001/images/",
};

module.exports = config;
