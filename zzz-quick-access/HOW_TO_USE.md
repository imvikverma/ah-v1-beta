# How to Use the Quick Access Launcher

## Running the Script

1. **Open PowerShell** in your project directory, or navigate to the project root:
   ```powershell
   cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
   ```

2. **Run the launcher**:
   ```powershell
   .\zzz-quick-access\start-all.ps1
   ```

3. **You'll see a menu** like this:
   ```
   ========================================
      AurumHarmony Service Launcher       
   ========================================

   Select a service to start:

     1. Flask Backend (port 5000)
     2. Ngrok Tunnel
     3. Flask Backend + Ngrok (both)
     4. Flutter Dev Server
     5. Flask Backend + Ngrok + Flutter (all three)
     6. Test HDFC Sky Credentials
     7. Test Kotak Neo Credentials
     8. Exit

   Enter your choice (1-8): _
   ```

4. **Type your number** (1-8) directly in the terminal where the cursor is blinking, then press **Enter**.

## Example

```
Enter your choice (1-8): 5
```

Just type `5` and press Enter to start all three services!

## Tips

- The script will wait for your input - just type the number and press Enter
- After selecting an option, the service(s) will start automatically
- For options that open new windows (like option 5), you'll see multiple PowerShell windows open
- You can run the script again anytime to start/stop services
