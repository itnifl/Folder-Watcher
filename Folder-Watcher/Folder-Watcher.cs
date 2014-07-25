using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Threading;

namespace Folder_Watcher {
   public partial class Service : ServiceBase {
      Watcher ourWatcher;
      TaskFactory myFactory = new TaskFactory();
      CancellationTokenSource cts = new CancellationTokenSource();
      EventLog logger = new EventLog();

      public Service() {
         InitializeComponent();
         this.EventLog.Log = "Application";
         this.CanHandlePowerEvent = false;
         this.CanHandleSessionChangeEvent = false;
         this.CanPauseAndContinue = false;
         this.CanShutdown = false;
         this.CanStop = true;
         logger.Source = "Folder-Watcher";
      }
      /*static void Main() {
         ServiceBase.Run(new Service());
      }*/
      //This method is used to raise event during start of service
      protected override void OnStart(string[] args) {
         CancellationToken token = cts.Token;
         try {
            logger.WriteEntry("Starting service Folder-watcher.", EventLogEntryType.Information);
            myFactory.StartNew(() => {
               ourWatcher = new Watcher(cts);
               while (ourWatcher.IsRunning()) {
                  ourWatcher.WaitForChanged();
                  if (token.IsCancellationRequested) {
                     ourWatcher.Stop();
                     token.ThrowIfCancellationRequested();
                  }
               }
            }, token);
         } catch (Exception e) {
            logger.WriteEntry("Failed starting service Folder-watcher." + e.ToString(), EventLogEntryType.Error);
         }
      }
      //This method is used to stop the service
      protected override void OnStop() {
         try {
            cts.Cancel();
            logger.WriteEntry("Stopping service Folder-watcher.", EventLogEntryType.Information);
         } catch(Exception e) {
            logger.WriteEntry("Failed trying to stop watcher process: " + e.ToString(), EventLogEntryType.Error);
         }
      }
   }
}