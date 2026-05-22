class BlockchainRecord {
  final String touristId;
  final String blockHash;
  final String identityHash;
  final String qrData;
  final String issuedAt;

  const BlockchainRecord({
    required this.touristId,
    required this.blockHash,
    required this.identityHash,
    required this.qrData,
    required this.issuedAt,
  });

  BlockchainRecord copyWith({
    String? touristId,
    String? blockHash,
    String? identityHash,
    String? qrData,
    String? issuedAt,
  }) {
    return BlockchainRecord(
      touristId: touristId ?? this.touristId,
      blockHash: blockHash ?? this.blockHash,
      identityHash: identityHash ?? this.identityHash,
      qrData: qrData ?? this.qrData,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tourist_id': touristId,
      'block_hash': blockHash,
      'identity_hash': identityHash,
      'qr_data': qrData,
      'issued_at': issuedAt,
    };
  }

  factory BlockchainRecord.fromJson(Map<String, dynamic> json) {
    return BlockchainRecord(
      touristId: (json['tourist_id'] ?? json['touristId'] ?? '') as String,
      blockHash: (json['block_hash'] ?? json['blockHash'] ?? '') as String,
      identityHash: (json['identity_hash'] ?? json['identityHash'] ?? '') as String,
      qrData: (json['qr_data'] ?? json['qrData'] ?? '') as String,
      issuedAt: (json['issued_at'] ?? json['issuedAt'] ?? '') as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockchainRecord &&
        other.touristId == touristId &&
        other.blockHash == blockHash &&
        other.identityHash == identityHash &&
        other.qrData == qrData &&
        other.issuedAt == issuedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      touristId,
      blockHash,
      identityHash,
      qrData,
      issuedAt,
    );
  }

  @override
  String toString() {
    return 'BlockchainRecord(touristId: $touristId, blockHash: $blockHash, identityHash: $identityHash, qrData: $qrData, issuedAt: $issuedAt)';
  }
}
