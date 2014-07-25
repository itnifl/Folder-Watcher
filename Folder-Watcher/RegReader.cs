using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Win32;
using System.Diagnostics;

namespace Folder_Watcher {
   class RegReader {
      private RegistryHive baseRegistryHive;
      EventLog logger = new EventLog();

      public RegReader(RegistryHive baseRegistryHive, string loggerSource) {
         logger.Source = loggerSource; //feks "Folder-Watcher";
         this.baseRegistryHive = baseRegistryHive; //feks RegistryHive.LocalMachine;
      }

      public string Read(string keyPath, string keyName) {
         //KeyPath feks SOFTWARE\\Folder-Watcher
         //KeyName feks configSource
         RegistryKey baseKey = RegistryKey.OpenRemoteBaseKey(baseRegistryHive, "");
         RegistryKey subKey = baseKey.OpenSubKey(keyPath);
         if (subKey == null) {
            return null;
         } else {
            try {
               return (string)subKey.GetValue(keyName);
            } catch (Exception e) {
               logger.WriteEntry("Error reading registry " + e.ToString(), EventLogEntryType.Error);
               return null;
            }

         }
      }
      public RegistryHive BaseRegistryHive {
         get { return baseRegistryHive; }
         set { baseRegistryHive = value; }
      }
   }
}
