# Mandi — Maintenance & Continuous Improvement Roadmap (Phase 9)

## 1. Post-Launch Maintenance Plan
1. **Performance Monitoring:**
   - Monitor database query response times in Supabase Dashboard (target: `< 150ms` for ledger lookups).
   - Track frame render times using `LiquidCrystalBackground` benchmarking harness (target: 60/120 FPS).
2. **Weekly Integrity Audits:**
   - Run `CloudBackupVerificationService.verifyShopBackupIntegrity()` across all active shops to detect any mathematical imbalance.
3. **Dependency Upgrades:**
   - Monthly check with `flutter pub outdated` for security patches.

## 2. Future Development Roadmap

### Short-Term (Months 1 - 2)
- [ ] Push Notifications via Firebase Cloud Messaging (FCM) webhook triggers from Supabase.
- [ ] USB OTG direct ESC/POS printer driver support for physical desktop Kanda terminals.

### Medium-Term (Months 3 - 6)
- [ ] Real-time commodity price forecasting based on historical season data.
- [ ] Automated WhatsApp Chatbot for farmers to query their passbook balance via conversational AI.

### Long-Term (Year 1)
- [ ] Cross-border multi-currency settlement gateway with Afghan Afghani (AFN) exchange rates.
- [ ] Satellite weather and crop harvest arrival tracking for Mandi market committees.
