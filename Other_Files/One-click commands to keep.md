git push origin main                           # frontend
cd ../aurum-api-worker && wrangler deploy      # backend
curl https://api.ah.saffronbolt.in/health      # sanity check