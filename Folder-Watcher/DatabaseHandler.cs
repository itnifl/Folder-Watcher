using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;
using System.Xml;
using System.Diagnostics;

namespace Folder_Watcher {
   class DatabaseHandler {
      XmlTextReader reader;
      EventLog logger = new EventLog();
      String SQLServer, SQLUser, SQLPass, SQLCatalog;
      SqlConnection conn;

      public DatabaseHandler(string xmlFil) {
         reader = new XmlTextReader(xmlFil);
         logger.Source = "Folder-Watcher";
         Boolean readSQLServer = false;
         Boolean readSQLUser = false;
         Boolean readSQLPass = false;
         Boolean readSQLCatalog = false;

         while (reader.Read()) {
            switch (reader.NodeType) {
               case XmlNodeType.Element:
                  if (reader.Name.ToString() == "SQLServer") readSQLServer = true;
                  else readSQLServer = false;
                  if (reader.Name.ToString() == "SQLUser") readSQLUser = true;
                  else readSQLUser = false;
                  if (reader.Name.ToString() == "SQLPass") readSQLPass = true;
                  else readSQLPass = false;
                  if (reader.Name.ToString() == "SQLCatalog") readSQLCatalog = true;
                  else readSQLCatalog = false;
                  break;
               case XmlNodeType.Text:
                  if (readSQLServer) SQLServer = reader.Value.ToString();
                  if (readSQLUser) SQLUser = reader.Value.ToString();
                  if (readSQLPass) SQLPass = reader.Value.ToString();
                  if (readSQLCatalog) SQLCatalog = reader.Value.ToString();
                  break;
               case XmlNodeType.EndElement:
                  break;
            }
         }
         reader.Close();
         if (SQLServer == null || SQLCatalog == null || SQLServer == "" || SQLCatalog == "") {
            logger.WriteEntry("Missing SQL Server Config, is " + xmlFil.ToString() + " missing or misconfigured?", EventLogEntryType.Error);
            throw new ArgumentException("Missing SQL Server Config, is " + xmlFil.ToString() + " missing or misconfigured?", "SQL Server Config");
         }
      }
      ~DatabaseHandler() {
         if (conn != null) {
            try {
               conn.Close();
            } catch (Exception) {
               //Do nothing
            }
         }
      }
      public SqlConnection ConnectToSql() {
         if (conn == null) conn = new SqlConnection();
         if (SQLUser == null || SQLUser == "") {
            conn.ConnectionString = "Integrated Security=SSPI;"
               + "Data Source=" + SQLServer + ";"
               + "initial catalog=" + SQLCatalog + ";";
         } else {
            conn.ConnectionString = "Integrated Security=False;"
            + "Data Source=" + SQLServer + ";"
            + "initial catalog=" + SQLCatalog + ";"
            + "User ID=" + SQLUser + ";"
            + "Password=" + SQLPass;
         }
         try {
            conn.Open();
         } catch (Exception ex) {
            logger.WriteEntry("Failed trying to open SQL connection " + ex.ToString(), EventLogEntryType.Error);
            throw ex;
         }
         return conn;
      }
   }
   class DBInsert : DatabaseHandler {
      SqlConnection conn;
      public DBInsert(string xmlFil)
         : base(xmlFil) {

      }
      public void DoInsert(string nonQueryString) {
         if (conn == null) conn = ConnectToSql();
         SqlCommand sqlSetning = new SqlCommand();
         string sqlInsert = nonQueryString;

         sqlSetning.CommandText = sqlInsert;
         sqlSetning.Connection = conn;
         sqlSetning.ExecuteNonQuery();
      }
   }
}