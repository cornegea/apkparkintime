import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  const WalletCard();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 140,
      left: 20,
      right: 20,
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF2ECC40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            "IDR 100.000",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            "Top up Wallet",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[600],
          ),
          onTap: () {
            // TODO: Tambahkan aksi top-up
          },
        ),
      ),
    );
  }
}
