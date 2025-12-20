- `flutter_app/` = root of the Flutter project (where pubspec.yaml lives).
- `assets/animations/` = subfolder for your Lottie .json files.

### Final Steps to Make It Work
1. **Confirm Files Are There**  
   Inside `.../assets/animations/` you should have:
   - loading.json
   - success.json
   - failure.json

2. **Update pubspec.yaml** (in `flutter_app/` folder)
   ```yaml
   flutter:
     assets:
       - assets/animations/loading.json
       - assets/animations/success.json
       - assets/animations/failure.json
   ```

   Make sure indentation is exact (2 spaces under assets).

3. **Run Commands**
   ```bash
   cd aurum_harmony/frontend/flutter_app
   flutter pub get
   flutter clean   # Optional, clears cache
   flutter run
   ```

4. **Hot Restart** (important for new assets)  
   In running app: Press `R` (hot restart) or stop and rerun.

