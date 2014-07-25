using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Xml;
using Microsoft.Win32;
using System.Diagnostics;
using System.Threading;

namespace Folder_Watcher {
   class Watcher {
      private FileSystemWatcher folderWatcher = new FileSystemWatcher();
      private XmlTextReader reader;
      private RegReader regReader;
      private string ConfigSource = "";
      private EventLog logger = new EventLog();
      private Boolean OnChangedMode = true;
      private Boolean OnCreatedMode = true;
      private Boolean OnDeletedMode = true;
      private Boolean OnRenamedMode = true;
      private static string regConfigPath = "SOFTWARE\\Folder-Watcher";
      private static string regKey = "configSource";
      private static string defaultConfigPath = Environment.ExpandEnvironmentVariables("%PROGRAMFILES%") + "\\Folder-Watcher\\mainConfig.xml";
      private CancellationTokenSource cts;

      public Watcher(CancellationTokenSource cts) {
         this.cts = cts;
         Boolean readWatchPath = false;
         Boolean readOnChangeMode = false;
         Boolean readOnCreatedMode = false;
         Boolean readOnDeletedMode = false;
         Boolean readOnRenamedMode = false;
         string watchPath = "";
         logger.Source = "Folder-Watcher";
         regReader = new RegReader(RegistryHive.LocalMachine, "Folder-Watcher");
         ConfigSource = regReader.Read(regConfigPath, regKey);
         if (string.IsNullOrEmpty(ConfigSource)) {
            ConfigSource = defaultConfigPath;
            logger.WriteEntry("Did not find configuration entry in registry under " + regConfigPath + ", reverting to default path " + defaultConfigPath, EventLogEntryType.Information);
            if (!File.Exists(defaultConfigPath)) {
               logger.WriteEntry("Did not find configuration file under " + defaultConfigPath, EventLogEntryType.Error);
               if (cts != null) cts.Cancel();
            }
         }
         try {
            reader = new XmlTextReader(ConfigSource);
         } catch (Exception) {
            logger.WriteEntry("Could not initialize xml reader for reading configuration file.", EventLogEntryType.Error);
            if (cts != null) cts.Cancel();
         }
         while (reader.Read()) {
            switch (reader.NodeType) {
               case XmlNodeType.Element:
                  if (reader.Name.ToString() == "WatchPath") readWatchPath = true;
                  else readWatchPath = false;
                  if (reader.Name.ToString() == "OnChangedMode") readOnChangeMode = true;
                  else readOnChangeMode = false;
                  if (reader.Name.ToString() == "OnRenamedMode") readOnRenamedMode = true;
                  else readOnRenamedMode = false;
                  if (reader.Name.ToString() == "OnCreatedMode") readOnCreatedMode = true;
                  else readOnCreatedMode = false;
                  if (reader.Name.ToString() == "OnDeletedMode") readOnDeletedMode = true;
                  else readOnDeletedMode = false;
                  break;
               case XmlNodeType.Text:
                  if (readWatchPath) watchPath = reader.Value.ToString();
                  if (readOnChangeMode) OnChangedMode = (reader.Value.ToString().ToLower() == "true" ? true : false);
                  if (readOnRenamedMode) OnRenamedMode = (reader.Value.ToString().ToLower() == "true" ? true : false);
                  if (readOnCreatedMode) OnCreatedMode = (reader.Value.ToString().ToLower() == "true" ? true : false);
                  if (readOnDeletedMode) OnDeletedMode = (reader.Value.ToString().ToLower() == "true" ? true : false);
                  break;
               case XmlNodeType.EndElement:
                  break;
            }
         }
         reader.Close();
         folderWatcher.Path = watchPath;
         folderWatcher.IncludeSubdirectories = true;
         folderWatcher.NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.CreationTime | NotifyFilters.LastWrite;
         folderWatcher.Filter = "*.*";
          
         if (OnChangedMode) folderWatcher.Changed += new FileSystemEventHandler(OnChanged);
         if (OnCreatedMode) folderWatcher.Created += new FileSystemEventHandler(OnChanged);
         if (OnDeletedMode) folderWatcher.Deleted += new FileSystemEventHandler(OnChanged);         
         if (OnRenamedMode) folderWatcher.Renamed += new RenamedEventHandler(OnRenamed);
         folderWatcher.EnableRaisingEvents = true;
      }

      public static void OnChanged(object source, FileSystemEventArgs e) {
         EventLog logger = new EventLog();
         logger.Source = "Folder-Watcher";
         RegReader regReader = new RegReader(RegistryHive.LocalMachine, "Folder-Watcher");
         string ConfigSource = regReader.Read(regConfigPath, regKey);
         if (string.IsNullOrEmpty(ConfigSource)) {
            ConfigSource = defaultConfigPath;
            logger.WriteEntry("Did not find configuration entry in registry under " + regConfigPath + ", reverting to default path " + defaultConfigPath, EventLogEntryType.Information);
            if (!File.Exists(defaultConfigPath)) {
               logger.WriteEntry("Did not find configuration file under " + defaultConfigPath, EventLogEntryType.Error);
               return;
            }
         }
         try {
            DBInsert DBInserter = new DBInsert(ConfigSource);
            DBInserter.DoInsert(string.Format("INSERT INTO register (name,change_event,date_registered,fullpath) VALUES ('{0}','{1}',(SELECT SYSDATETIME()),'{2}');", e.Name, e.ChangeType, e.FullPath));
         } catch (Exception ex) {
            logger.WriteEntry("Failed trying to insert to database at OnChanged in main Watcher " + ex.ToString(), EventLogEntryType.Error);
            return;
         }
      }

      public static void OnRenamed(object source, RenamedEventArgs e) {
         EventLog logger = new EventLog();
         logger.Source = "Folder-Watcher";
         RegReader regReader = new RegReader(RegistryHive.LocalMachine, "Folder-Watcher");
         string ConfigSource = regReader.Read(regConfigPath, regKey);
         if (string.IsNullOrEmpty(ConfigSource)) {
            ConfigSource = defaultConfigPath;
            logger.WriteEntry("Did not find configuration entry in registry under " + regConfigPath + ", reverting to default path " + defaultConfigPath, EventLogEntryType.Information);
            if (!File.Exists(defaultConfigPath)) {
               logger.WriteEntry("Did not find configuration file under " + defaultConfigPath, EventLogEntryType.Error);
               return;
            }
         }
         try {
            DBInsert DBInserter = new DBInsert(ConfigSource);
            DBInserter.DoInsert(string.Format("INSERT INTO register (name,change_event,date_registered,fullpath,n_fullpath) VALUES ('{0}','{1}',(SELECT SYSDATETIME()),'{2}','{3}');", e.Name, e.ChangeType, e.OldFullPath, e.FullPath));
         } catch (Exception ex) {
            logger.WriteEntry("Failed trying to insert to database at OnRenamed in main Watcher " + ex.ToString(), EventLogEntryType.Error);
            return;
         }
      }

      public bool IsRunning() {
         try {
            if (folderWatcher == null) return false;
         } catch (Exception) {
            return false;
         }
         return true;
      }
      public void WaitForChanged() {
         folderWatcher.WaitForChanged(WatcherChangeTypes.All);
      }
      public void Stop() {
         folderWatcher.EnableRaisingEvents = false;
         folderWatcher.Path = "";
      }
   }
}
