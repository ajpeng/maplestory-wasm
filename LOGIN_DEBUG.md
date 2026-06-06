# MapleStory WASM Login Debug Guide

## Issue: Login works but UI doesn't advance to server selection

### Current Status ✅
- Login is working (server validates password)
- Server returns error for wrong password
- All 16 NX files + List.wz present
- Cosmic server running with multiple worlds configured

### Debugging Steps:

## 1. Browser Console Check
**Open browser DevTools (F12) → Console tab**

Look for these types of errors:
- `WebAssembly errors`
- `UI state transition errors` 
- `Asset loading failures`
- `WebSocket connection issues`

## 2. Test Credentials
Try these valid credentials:
- **Username**: `testuser`
- **Password**: `password`

## 3. Common Solutions

### A. UI Asset Issue (Most Likely)
The client may be missing specific UI assets for the server selection screen.

**Check**: Look in browser console for missing texture/UI errors

**Solution**: The UI.wz from v153+ should contain the server selection UI, but may need specific UI.nx rebuilding

### B. WebSocket Timing Issue  
The server response may be timing out or getting lost.

**Check**: In DevTools → Network tab, monitor WebSocket messages during login

**Solution**: May need to increase timeouts in the client

### C. WASM Memory/Canvas Issue
The WASM client may be hitting memory limits or canvas rendering issues.

**Check**: Look for WebAssembly memory errors in console
**Solution**: Try in a different browser or refresh the page

## 4. Advanced Debugging

### Monitor Server Communication:
```bash
# Watch server logs in real-time
tail -f ~/Maplestory/Cosmic/cosmic-restart.log

# Watch WebSocket proxy
docker-compose logs -f ws-proxy
```

### Check Database Accounts:
```bash
# Verify account was created
docker exec cosmic-db-1 mysql -u root cosmic -e "SELECT name, password FROM accounts WHERE name='testuser';"
```

## 5. Expected Login Flow:
1. **Login Screen** → Enter credentials
2. **Login Validation** → Server checks credentials  
3. **Server List Request** → Client requests world list
4. **Server Selection UI** → Shows worlds (Scania, Bera, etc.)
5. **Channel Selection** → Shows channels within selected world
6. **Character Selection** → Shows character list

**Current Status**: Stuck between steps 3-4 (server list not displaying)

## 6. Immediate Actions to Try:

1. **Try valid credentials** (`testuser` / `password`)
2. **Check browser console** during login attempt
3. **Try different browser** (Chrome vs Firefox)
4. **Hard refresh** the page (Ctrl+Shift+R)
5. **Clear browser cache** and reload

## Next Steps:
If these don't work, we may need to:
- Check specific UI asset paths in the WASM client
- Verify the server list packet format
- Check client-side UI state machine logic

---
*Created: 2026-06-05 - Login Debug Session*