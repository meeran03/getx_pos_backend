// configuration for mssql connector
const config = {
    // connectionString: `Driver=SQL Server;Server=.\\SQLEXPRESS;Database=Getx;Trusted_Connection=False;`,
    connectionString: 'Driver=SQL Server;Server=tcp:meeran.database.windows.net,1433;Database=Getx;Uid=meeran;Pwd=DbProject@321;',
    secretOrKey: "secret",
    image_url: "http://localhost:5001/images/",
};

module.exports = config;
