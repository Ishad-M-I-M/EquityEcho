// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderAddressMeta = const VerificationMeta(
    'senderAddress',
  );
  @override
  late final GeneratedColumn<String> senderAddress = GeneratedColumn<String>(
    'sender_address',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyTemplateMeta = const VerificationMeta(
    'buyTemplate',
  );
  @override
  late final GeneratedColumn<String> buyTemplate = GeneratedColumn<String>(
    'buy_template',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellTemplateMeta = const VerificationMeta(
    'sellTemplate',
  );
  @override
  late final GeneratedColumn<String> sellTemplate = GeneratedColumn<String>(
    'sell_template',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fundTemplateMeta = const VerificationMeta(
    'fundTemplate',
  );
  @override
  late final GeneratedColumn<String> fundTemplate = GeneratedColumn<String>(
    'fund_template',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LKR'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    senderAddress,
    buyTemplate,
    sellTemplate,
    fundTemplate,
    currency,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Channel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sender_address')) {
      context.handle(
        _senderAddressMeta,
        senderAddress.isAcceptableOrUnknown(
          data['sender_address']!,
          _senderAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderAddressMeta);
    }
    if (data.containsKey('buy_template')) {
      context.handle(
        _buyTemplateMeta,
        buyTemplate.isAcceptableOrUnknown(
          data['buy_template']!,
          _buyTemplateMeta,
        ),
      );
    }
    if (data.containsKey('sell_template')) {
      context.handle(
        _sellTemplateMeta,
        sellTemplate.isAcceptableOrUnknown(
          data['sell_template']!,
          _sellTemplateMeta,
        ),
      );
    }
    if (data.containsKey('fund_template')) {
      context.handle(
        _fundTemplateMeta,
        fundTemplate.isAcceptableOrUnknown(
          data['fund_template']!,
          _fundTemplateMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      senderAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_address'],
      )!,
      buyTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buy_template'],
      ),
      sellTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sell_template'],
      ),
      fundTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fund_template'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class Channel extends DataClass implements Insertable<Channel> {
  final String id;
  final String name;
  final String senderAddress;
  final String? buyTemplate;
  final String? sellTemplate;
  final String? fundTemplate;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Channel({
    required this.id,
    required this.name,
    required this.senderAddress,
    this.buyTemplate,
    this.sellTemplate,
    this.fundTemplate,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sender_address'] = Variable<String>(senderAddress);
    if (!nullToAbsent || buyTemplate != null) {
      map['buy_template'] = Variable<String>(buyTemplate);
    }
    if (!nullToAbsent || sellTemplate != null) {
      map['sell_template'] = Variable<String>(sellTemplate);
    }
    if (!nullToAbsent || fundTemplate != null) {
      map['fund_template'] = Variable<String>(fundTemplate);
    }
    map['currency'] = Variable<String>(currency);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      name: Value(name),
      senderAddress: Value(senderAddress),
      buyTemplate: buyTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(buyTemplate),
      sellTemplate: sellTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(sellTemplate),
      fundTemplate: fundTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(fundTemplate),
      currency: Value(currency),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Channel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      senderAddress: serializer.fromJson<String>(json['senderAddress']),
      buyTemplate: serializer.fromJson<String?>(json['buyTemplate']),
      sellTemplate: serializer.fromJson<String?>(json['sellTemplate']),
      fundTemplate: serializer.fromJson<String?>(json['fundTemplate']),
      currency: serializer.fromJson<String>(json['currency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'senderAddress': serializer.toJson<String>(senderAddress),
      'buyTemplate': serializer.toJson<String?>(buyTemplate),
      'sellTemplate': serializer.toJson<String?>(sellTemplate),
      'fundTemplate': serializer.toJson<String?>(fundTemplate),
      'currency': serializer.toJson<String>(currency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Channel copyWith({
    String? id,
    String? name,
    String? senderAddress,
    Value<String?> buyTemplate = const Value.absent(),
    Value<String?> sellTemplate = const Value.absent(),
    Value<String?> fundTemplate = const Value.absent(),
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Channel(
    id: id ?? this.id,
    name: name ?? this.name,
    senderAddress: senderAddress ?? this.senderAddress,
    buyTemplate: buyTemplate.present ? buyTemplate.value : this.buyTemplate,
    sellTemplate: sellTemplate.present ? sellTemplate.value : this.sellTemplate,
    fundTemplate: fundTemplate.present ? fundTemplate.value : this.fundTemplate,
    currency: currency ?? this.currency,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      senderAddress: data.senderAddress.present
          ? data.senderAddress.value
          : this.senderAddress,
      buyTemplate: data.buyTemplate.present
          ? data.buyTemplate.value
          : this.buyTemplate,
      sellTemplate: data.sellTemplate.present
          ? data.sellTemplate.value
          : this.sellTemplate,
      fundTemplate: data.fundTemplate.present
          ? data.fundTemplate.value
          : this.fundTemplate,
      currency: data.currency.present ? data.currency.value : this.currency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('senderAddress: $senderAddress, ')
          ..write('buyTemplate: $buyTemplate, ')
          ..write('sellTemplate: $sellTemplate, ')
          ..write('fundTemplate: $fundTemplate, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    senderAddress,
    buyTemplate,
    sellTemplate,
    fundTemplate,
    currency,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.name == this.name &&
          other.senderAddress == this.senderAddress &&
          other.buyTemplate == this.buyTemplate &&
          other.sellTemplate == this.sellTemplate &&
          other.fundTemplate == this.fundTemplate &&
          other.currency == this.currency &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> senderAddress;
  final Value<String?> buyTemplate;
  final Value<String?> sellTemplate;
  final Value<String?> fundTemplate;
  final Value<String> currency;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.senderAddress = const Value.absent(),
    this.buyTemplate = const Value.absent(),
    this.sellTemplate = const Value.absent(),
    this.fundTemplate = const Value.absent(),
    this.currency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsCompanion.insert({
    required String id,
    required String name,
    required String senderAddress,
    this.buyTemplate = const Value.absent(),
    this.sellTemplate = const Value.absent(),
    this.fundTemplate = const Value.absent(),
    this.currency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       senderAddress = Value(senderAddress);
  static Insertable<Channel> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? senderAddress,
    Expression<String>? buyTemplate,
    Expression<String>? sellTemplate,
    Expression<String>? fundTemplate,
    Expression<String>? currency,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (senderAddress != null) 'sender_address': senderAddress,
      if (buyTemplate != null) 'buy_template': buyTemplate,
      if (sellTemplate != null) 'sell_template': sellTemplate,
      if (fundTemplate != null) 'fund_template': fundTemplate,
      if (currency != null) 'currency': currency,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? senderAddress,
    Value<String?>? buyTemplate,
    Value<String?>? sellTemplate,
    Value<String?>? fundTemplate,
    Value<String>? currency,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      senderAddress: senderAddress ?? this.senderAddress,
      buyTemplate: buyTemplate ?? this.buyTemplate,
      sellTemplate: sellTemplate ?? this.sellTemplate,
      fundTemplate: fundTemplate ?? this.fundTemplate,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (senderAddress.present) {
      map['sender_address'] = Variable<String>(senderAddress.value);
    }
    if (buyTemplate.present) {
      map['buy_template'] = Variable<String>(buyTemplate.value);
    }
    if (sellTemplate.present) {
      map['sell_template'] = Variable<String>(sellTemplate.value);
    }
    if (fundTemplate.present) {
      map['fund_template'] = Variable<String>(fundTemplate.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('senderAddress: $senderAddress, ')
          ..write('buyTemplate: $buyTemplate, ')
          ..write('sellTemplate: $sellTemplate, ')
          ..write('fundTemplate: $fundTemplate, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TradesTable extends Trades with TableInfo<$TradesTable, Trade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TradesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels (id)',
    ),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalValueMeta = const VerificationMeta(
    'totalValue',
  );
  @override
  late final GeneratedColumn<double> totalValue = GeneratedColumn<double>(
    'total_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smsDateMeta = const VerificationMeta(
    'smsDate',
  );
  @override
  late final GeneratedColumn<DateTime> smsDate = GeneratedColumn<DateTime>(
    'sms_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smsReceivedDateMeta = const VerificationMeta(
    'smsReceivedDate',
  );
  @override
  late final GeneratedColumn<DateTime> smsReceivedDate =
      GeneratedColumn<DateTime>(
        'sms_received_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rawSmsBodyMeta = const VerificationMeta(
    'rawSmsBody',
  );
  @override
  late final GeneratedColumn<String> rawSmsBody = GeneratedColumn<String>(
    'raw_sms_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isManualMeta = const VerificationMeta(
    'isManual',
  );
  @override
  late final GeneratedColumn<bool> isManual = GeneratedColumn<bool>(
    'is_manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEditedMeta = const VerificationMeta(
    'isEdited',
  );
  @override
  late final GeneratedColumn<bool> isEdited = GeneratedColumn<bool>(
    'is_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelId,
    action,
    symbol,
    quantity,
    price,
    totalValue,
    smsDate,
    smsReceivedDate,
    rawSmsBody,
    createdAt,
    isManual,
    isEdited,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trades';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trade> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('total_value')) {
      context.handle(
        _totalValueMeta,
        totalValue.isAcceptableOrUnknown(data['total_value']!, _totalValueMeta),
      );
    } else if (isInserting) {
      context.missing(_totalValueMeta);
    }
    if (data.containsKey('sms_date')) {
      context.handle(
        _smsDateMeta,
        smsDate.isAcceptableOrUnknown(data['sms_date']!, _smsDateMeta),
      );
    } else if (isInserting) {
      context.missing(_smsDateMeta);
    }
    if (data.containsKey('sms_received_date')) {
      context.handle(
        _smsReceivedDateMeta,
        smsReceivedDate.isAcceptableOrUnknown(
          data['sms_received_date']!,
          _smsReceivedDateMeta,
        ),
      );
    }
    if (data.containsKey('raw_sms_body')) {
      context.handle(
        _rawSmsBodyMeta,
        rawSmsBody.isAcceptableOrUnknown(
          data['raw_sms_body']!,
          _rawSmsBodyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('is_manual')) {
      context.handle(
        _isManualMeta,
        isManual.isAcceptableOrUnknown(data['is_manual']!, _isManualMeta),
      );
    }
    if (data.containsKey('is_edited')) {
      context.handle(
        _isEditedMeta,
        isEdited.isAcceptableOrUnknown(data['is_edited']!, _isEditedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trade(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      totalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_value'],
      )!,
      smsDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sms_date'],
      )!,
      smsReceivedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sms_received_date'],
      ),
      rawSmsBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_sms_body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isManual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manual'],
      )!,
      isEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_edited'],
      )!,
    );
  }

  @override
  $TradesTable createAlias(String alias) {
    return $TradesTable(attachedDatabase, alias);
  }
}

class Trade extends DataClass implements Insertable<Trade> {
  final String id;
  final String channelId;
  final String action;
  final String symbol;
  final double quantity;
  final double price;
  final double totalValue;
  final DateTime smsDate;
  final DateTime? smsReceivedDate;
  final String rawSmsBody;
  final DateTime createdAt;
  final bool isManual;
  final bool isEdited;
  const Trade({
    required this.id,
    required this.channelId,
    required this.action,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.totalValue,
    required this.smsDate,
    this.smsReceivedDate,
    required this.rawSmsBody,
    required this.createdAt,
    required this.isManual,
    required this.isEdited,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['channel_id'] = Variable<String>(channelId);
    map['action'] = Variable<String>(action);
    map['symbol'] = Variable<String>(symbol);
    map['quantity'] = Variable<double>(quantity);
    map['price'] = Variable<double>(price);
    map['total_value'] = Variable<double>(totalValue);
    map['sms_date'] = Variable<DateTime>(smsDate);
    if (!nullToAbsent || smsReceivedDate != null) {
      map['sms_received_date'] = Variable<DateTime>(smsReceivedDate);
    }
    map['raw_sms_body'] = Variable<String>(rawSmsBody);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_manual'] = Variable<bool>(isManual);
    map['is_edited'] = Variable<bool>(isEdited);
    return map;
  }

  TradesCompanion toCompanion(bool nullToAbsent) {
    return TradesCompanion(
      id: Value(id),
      channelId: Value(channelId),
      action: Value(action),
      symbol: Value(symbol),
      quantity: Value(quantity),
      price: Value(price),
      totalValue: Value(totalValue),
      smsDate: Value(smsDate),
      smsReceivedDate: smsReceivedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(smsReceivedDate),
      rawSmsBody: Value(rawSmsBody),
      createdAt: Value(createdAt),
      isManual: Value(isManual),
      isEdited: Value(isEdited),
    );
  }

  factory Trade.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trade(
      id: serializer.fromJson<String>(json['id']),
      channelId: serializer.fromJson<String>(json['channelId']),
      action: serializer.fromJson<String>(json['action']),
      symbol: serializer.fromJson<String>(json['symbol']),
      quantity: serializer.fromJson<double>(json['quantity']),
      price: serializer.fromJson<double>(json['price']),
      totalValue: serializer.fromJson<double>(json['totalValue']),
      smsDate: serializer.fromJson<DateTime>(json['smsDate']),
      smsReceivedDate: serializer.fromJson<DateTime?>(json['smsReceivedDate']),
      rawSmsBody: serializer.fromJson<String>(json['rawSmsBody']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isManual: serializer.fromJson<bool>(json['isManual']),
      isEdited: serializer.fromJson<bool>(json['isEdited']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'channelId': serializer.toJson<String>(channelId),
      'action': serializer.toJson<String>(action),
      'symbol': serializer.toJson<String>(symbol),
      'quantity': serializer.toJson<double>(quantity),
      'price': serializer.toJson<double>(price),
      'totalValue': serializer.toJson<double>(totalValue),
      'smsDate': serializer.toJson<DateTime>(smsDate),
      'smsReceivedDate': serializer.toJson<DateTime?>(smsReceivedDate),
      'rawSmsBody': serializer.toJson<String>(rawSmsBody),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isManual': serializer.toJson<bool>(isManual),
      'isEdited': serializer.toJson<bool>(isEdited),
    };
  }

  Trade copyWith({
    String? id,
    String? channelId,
    String? action,
    String? symbol,
    double? quantity,
    double? price,
    double? totalValue,
    DateTime? smsDate,
    Value<DateTime?> smsReceivedDate = const Value.absent(),
    String? rawSmsBody,
    DateTime? createdAt,
    bool? isManual,
    bool? isEdited,
  }) => Trade(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    action: action ?? this.action,
    symbol: symbol ?? this.symbol,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    totalValue: totalValue ?? this.totalValue,
    smsDate: smsDate ?? this.smsDate,
    smsReceivedDate: smsReceivedDate.present
        ? smsReceivedDate.value
        : this.smsReceivedDate,
    rawSmsBody: rawSmsBody ?? this.rawSmsBody,
    createdAt: createdAt ?? this.createdAt,
    isManual: isManual ?? this.isManual,
    isEdited: isEdited ?? this.isEdited,
  );
  Trade copyWithCompanion(TradesCompanion data) {
    return Trade(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      action: data.action.present ? data.action.value : this.action,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      price: data.price.present ? data.price.value : this.price,
      totalValue: data.totalValue.present
          ? data.totalValue.value
          : this.totalValue,
      smsDate: data.smsDate.present ? data.smsDate.value : this.smsDate,
      smsReceivedDate: data.smsReceivedDate.present
          ? data.smsReceivedDate.value
          : this.smsReceivedDate,
      rawSmsBody: data.rawSmsBody.present
          ? data.rawSmsBody.value
          : this.rawSmsBody,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isManual: data.isManual.present ? data.isManual.value : this.isManual,
      isEdited: data.isEdited.present ? data.isEdited.value : this.isEdited,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trade(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('action: $action, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('totalValue: $totalValue, ')
          ..write('smsDate: $smsDate, ')
          ..write('smsReceivedDate: $smsReceivedDate, ')
          ..write('rawSmsBody: $rawSmsBody, ')
          ..write('createdAt: $createdAt, ')
          ..write('isManual: $isManual, ')
          ..write('isEdited: $isEdited')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    action,
    symbol,
    quantity,
    price,
    totalValue,
    smsDate,
    smsReceivedDate,
    rawSmsBody,
    createdAt,
    isManual,
    isEdited,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trade &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.action == this.action &&
          other.symbol == this.symbol &&
          other.quantity == this.quantity &&
          other.price == this.price &&
          other.totalValue == this.totalValue &&
          other.smsDate == this.smsDate &&
          other.smsReceivedDate == this.smsReceivedDate &&
          other.rawSmsBody == this.rawSmsBody &&
          other.createdAt == this.createdAt &&
          other.isManual == this.isManual &&
          other.isEdited == this.isEdited);
}

class TradesCompanion extends UpdateCompanion<Trade> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> action;
  final Value<String> symbol;
  final Value<double> quantity;
  final Value<double> price;
  final Value<double> totalValue;
  final Value<DateTime> smsDate;
  final Value<DateTime?> smsReceivedDate;
  final Value<String> rawSmsBody;
  final Value<DateTime> createdAt;
  final Value<bool> isManual;
  final Value<bool> isEdited;
  final Value<int> rowid;
  const TradesCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.action = const Value.absent(),
    this.symbol = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.totalValue = const Value.absent(),
    this.smsDate = const Value.absent(),
    this.smsReceivedDate = const Value.absent(),
    this.rawSmsBody = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isManual = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TradesCompanion.insert({
    required String id,
    required String channelId,
    required String action,
    required String symbol,
    required double quantity,
    required double price,
    required double totalValue,
    required DateTime smsDate,
    this.smsReceivedDate = const Value.absent(),
    this.rawSmsBody = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isManual = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       channelId = Value(channelId),
       action = Value(action),
       symbol = Value(symbol),
       quantity = Value(quantity),
       price = Value(price),
       totalValue = Value(totalValue),
       smsDate = Value(smsDate);
  static Insertable<Trade> custom({
    Expression<String>? id,
    Expression<String>? channelId,
    Expression<String>? action,
    Expression<String>? symbol,
    Expression<double>? quantity,
    Expression<double>? price,
    Expression<double>? totalValue,
    Expression<DateTime>? smsDate,
    Expression<DateTime>? smsReceivedDate,
    Expression<String>? rawSmsBody,
    Expression<DateTime>? createdAt,
    Expression<bool>? isManual,
    Expression<bool>? isEdited,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (action != null) 'action': action,
      if (symbol != null) 'symbol': symbol,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (totalValue != null) 'total_value': totalValue,
      if (smsDate != null) 'sms_date': smsDate,
      if (smsReceivedDate != null) 'sms_received_date': smsReceivedDate,
      if (rawSmsBody != null) 'raw_sms_body': rawSmsBody,
      if (createdAt != null) 'created_at': createdAt,
      if (isManual != null) 'is_manual': isManual,
      if (isEdited != null) 'is_edited': isEdited,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TradesCompanion copyWith({
    Value<String>? id,
    Value<String>? channelId,
    Value<String>? action,
    Value<String>? symbol,
    Value<double>? quantity,
    Value<double>? price,
    Value<double>? totalValue,
    Value<DateTime>? smsDate,
    Value<DateTime?>? smsReceivedDate,
    Value<String>? rawSmsBody,
    Value<DateTime>? createdAt,
    Value<bool>? isManual,
    Value<bool>? isEdited,
    Value<int>? rowid,
  }) {
    return TradesCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      action: action ?? this.action,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalValue: totalValue ?? this.totalValue,
      smsDate: smsDate ?? this.smsDate,
      smsReceivedDate: smsReceivedDate ?? this.smsReceivedDate,
      rawSmsBody: rawSmsBody ?? this.rawSmsBody,
      createdAt: createdAt ?? this.createdAt,
      isManual: isManual ?? this.isManual,
      isEdited: isEdited ?? this.isEdited,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (totalValue.present) {
      map['total_value'] = Variable<double>(totalValue.value);
    }
    if (smsDate.present) {
      map['sms_date'] = Variable<DateTime>(smsDate.value);
    }
    if (smsReceivedDate.present) {
      map['sms_received_date'] = Variable<DateTime>(smsReceivedDate.value);
    }
    if (rawSmsBody.present) {
      map['raw_sms_body'] = Variable<String>(rawSmsBody.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isManual.present) {
      map['is_manual'] = Variable<bool>(isManual.value);
    }
    if (isEdited.present) {
      map['is_edited'] = Variable<bool>(isEdited.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TradesCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('action: $action, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('totalValue: $totalValue, ')
          ..write('smsDate: $smsDate, ')
          ..write('smsReceivedDate: $smsReceivedDate, ')
          ..write('rawSmsBody: $rawSmsBody, ')
          ..write('createdAt: $createdAt, ')
          ..write('isManual: $isManual, ')
          ..write('isEdited: $isEdited, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FundTransfersTable extends FundTransfers
    with TableInfo<$FundTransfersTable, FundTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels (id)',
    ),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smsDateMeta = const VerificationMeta(
    'smsDate',
  );
  @override
  late final GeneratedColumn<DateTime> smsDate = GeneratedColumn<DateTime>(
    'sms_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smsReceivedDateMeta = const VerificationMeta(
    'smsReceivedDate',
  );
  @override
  late final GeneratedColumn<DateTime> smsReceivedDate =
      GeneratedColumn<DateTime>(
        'sms_received_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rawSmsBodyMeta = const VerificationMeta(
    'rawSmsBody',
  );
  @override
  late final GeneratedColumn<String> rawSmsBody = GeneratedColumn<String>(
    'raw_sms_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isManualMeta = const VerificationMeta(
    'isManual',
  );
  @override
  late final GeneratedColumn<bool> isManual = GeneratedColumn<bool>(
    'is_manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelId,
    action,
    amount,
    smsDate,
    smsReceivedDate,
    rawSmsBody,
    createdAt,
    isManual,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fund_transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<FundTransfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('sms_date')) {
      context.handle(
        _smsDateMeta,
        smsDate.isAcceptableOrUnknown(data['sms_date']!, _smsDateMeta),
      );
    } else if (isInserting) {
      context.missing(_smsDateMeta);
    }
    if (data.containsKey('sms_received_date')) {
      context.handle(
        _smsReceivedDateMeta,
        smsReceivedDate.isAcceptableOrUnknown(
          data['sms_received_date']!,
          _smsReceivedDateMeta,
        ),
      );
    }
    if (data.containsKey('raw_sms_body')) {
      context.handle(
        _rawSmsBodyMeta,
        rawSmsBody.isAcceptableOrUnknown(
          data['raw_sms_body']!,
          _rawSmsBodyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('is_manual')) {
      context.handle(
        _isManualMeta,
        isManual.isAcceptableOrUnknown(data['is_manual']!, _isManualMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FundTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FundTransfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      smsDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sms_date'],
      )!,
      smsReceivedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sms_received_date'],
      ),
      rawSmsBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_sms_body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isManual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manual'],
      )!,
    );
  }

  @override
  $FundTransfersTable createAlias(String alias) {
    return $FundTransfersTable(attachedDatabase, alias);
  }
}

class FundTransfer extends DataClass implements Insertable<FundTransfer> {
  final String id;
  final String channelId;
  final String action;
  final double amount;
  final DateTime smsDate;
  final DateTime? smsReceivedDate;
  final String rawSmsBody;
  final DateTime createdAt;
  final bool isManual;
  const FundTransfer({
    required this.id,
    required this.channelId,
    required this.action,
    required this.amount,
    required this.smsDate,
    this.smsReceivedDate,
    required this.rawSmsBody,
    required this.createdAt,
    required this.isManual,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['channel_id'] = Variable<String>(channelId);
    map['action'] = Variable<String>(action);
    map['amount'] = Variable<double>(amount);
    map['sms_date'] = Variable<DateTime>(smsDate);
    if (!nullToAbsent || smsReceivedDate != null) {
      map['sms_received_date'] = Variable<DateTime>(smsReceivedDate);
    }
    map['raw_sms_body'] = Variable<String>(rawSmsBody);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_manual'] = Variable<bool>(isManual);
    return map;
  }

  FundTransfersCompanion toCompanion(bool nullToAbsent) {
    return FundTransfersCompanion(
      id: Value(id),
      channelId: Value(channelId),
      action: Value(action),
      amount: Value(amount),
      smsDate: Value(smsDate),
      smsReceivedDate: smsReceivedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(smsReceivedDate),
      rawSmsBody: Value(rawSmsBody),
      createdAt: Value(createdAt),
      isManual: Value(isManual),
    );
  }

  factory FundTransfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FundTransfer(
      id: serializer.fromJson<String>(json['id']),
      channelId: serializer.fromJson<String>(json['channelId']),
      action: serializer.fromJson<String>(json['action']),
      amount: serializer.fromJson<double>(json['amount']),
      smsDate: serializer.fromJson<DateTime>(json['smsDate']),
      smsReceivedDate: serializer.fromJson<DateTime?>(json['smsReceivedDate']),
      rawSmsBody: serializer.fromJson<String>(json['rawSmsBody']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isManual: serializer.fromJson<bool>(json['isManual']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'channelId': serializer.toJson<String>(channelId),
      'action': serializer.toJson<String>(action),
      'amount': serializer.toJson<double>(amount),
      'smsDate': serializer.toJson<DateTime>(smsDate),
      'smsReceivedDate': serializer.toJson<DateTime?>(smsReceivedDate),
      'rawSmsBody': serializer.toJson<String>(rawSmsBody),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isManual': serializer.toJson<bool>(isManual),
    };
  }

  FundTransfer copyWith({
    String? id,
    String? channelId,
    String? action,
    double? amount,
    DateTime? smsDate,
    Value<DateTime?> smsReceivedDate = const Value.absent(),
    String? rawSmsBody,
    DateTime? createdAt,
    bool? isManual,
  }) => FundTransfer(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    action: action ?? this.action,
    amount: amount ?? this.amount,
    smsDate: smsDate ?? this.smsDate,
    smsReceivedDate: smsReceivedDate.present
        ? smsReceivedDate.value
        : this.smsReceivedDate,
    rawSmsBody: rawSmsBody ?? this.rawSmsBody,
    createdAt: createdAt ?? this.createdAt,
    isManual: isManual ?? this.isManual,
  );
  FundTransfer copyWithCompanion(FundTransfersCompanion data) {
    return FundTransfer(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      action: data.action.present ? data.action.value : this.action,
      amount: data.amount.present ? data.amount.value : this.amount,
      smsDate: data.smsDate.present ? data.smsDate.value : this.smsDate,
      smsReceivedDate: data.smsReceivedDate.present
          ? data.smsReceivedDate.value
          : this.smsReceivedDate,
      rawSmsBody: data.rawSmsBody.present
          ? data.rawSmsBody.value
          : this.rawSmsBody,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isManual: data.isManual.present ? data.isManual.value : this.isManual,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FundTransfer(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('action: $action, ')
          ..write('amount: $amount, ')
          ..write('smsDate: $smsDate, ')
          ..write('smsReceivedDate: $smsReceivedDate, ')
          ..write('rawSmsBody: $rawSmsBody, ')
          ..write('createdAt: $createdAt, ')
          ..write('isManual: $isManual')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    action,
    amount,
    smsDate,
    smsReceivedDate,
    rawSmsBody,
    createdAt,
    isManual,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FundTransfer &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.action == this.action &&
          other.amount == this.amount &&
          other.smsDate == this.smsDate &&
          other.smsReceivedDate == this.smsReceivedDate &&
          other.rawSmsBody == this.rawSmsBody &&
          other.createdAt == this.createdAt &&
          other.isManual == this.isManual);
}

class FundTransfersCompanion extends UpdateCompanion<FundTransfer> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> action;
  final Value<double> amount;
  final Value<DateTime> smsDate;
  final Value<DateTime?> smsReceivedDate;
  final Value<String> rawSmsBody;
  final Value<DateTime> createdAt;
  final Value<bool> isManual;
  final Value<int> rowid;
  const FundTransfersCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.action = const Value.absent(),
    this.amount = const Value.absent(),
    this.smsDate = const Value.absent(),
    this.smsReceivedDate = const Value.absent(),
    this.rawSmsBody = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isManual = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FundTransfersCompanion.insert({
    required String id,
    required String channelId,
    required String action,
    required double amount,
    required DateTime smsDate,
    this.smsReceivedDate = const Value.absent(),
    this.rawSmsBody = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isManual = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       channelId = Value(channelId),
       action = Value(action),
       amount = Value(amount),
       smsDate = Value(smsDate);
  static Insertable<FundTransfer> custom({
    Expression<String>? id,
    Expression<String>? channelId,
    Expression<String>? action,
    Expression<double>? amount,
    Expression<DateTime>? smsDate,
    Expression<DateTime>? smsReceivedDate,
    Expression<String>? rawSmsBody,
    Expression<DateTime>? createdAt,
    Expression<bool>? isManual,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (action != null) 'action': action,
      if (amount != null) 'amount': amount,
      if (smsDate != null) 'sms_date': smsDate,
      if (smsReceivedDate != null) 'sms_received_date': smsReceivedDate,
      if (rawSmsBody != null) 'raw_sms_body': rawSmsBody,
      if (createdAt != null) 'created_at': createdAt,
      if (isManual != null) 'is_manual': isManual,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FundTransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? channelId,
    Value<String>? action,
    Value<double>? amount,
    Value<DateTime>? smsDate,
    Value<DateTime?>? smsReceivedDate,
    Value<String>? rawSmsBody,
    Value<DateTime>? createdAt,
    Value<bool>? isManual,
    Value<int>? rowid,
  }) {
    return FundTransfersCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      action: action ?? this.action,
      amount: amount ?? this.amount,
      smsDate: smsDate ?? this.smsDate,
      smsReceivedDate: smsReceivedDate ?? this.smsReceivedDate,
      rawSmsBody: rawSmsBody ?? this.rawSmsBody,
      createdAt: createdAt ?? this.createdAt,
      isManual: isManual ?? this.isManual,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (smsDate.present) {
      map['sms_date'] = Variable<DateTime>(smsDate.value);
    }
    if (smsReceivedDate.present) {
      map['sms_received_date'] = Variable<DateTime>(smsReceivedDate.value);
    }
    if (rawSmsBody.present) {
      map['raw_sms_body'] = Variable<String>(rawSmsBody.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isManual.present) {
      map['is_manual'] = Variable<bool>(isManual.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundTransfersCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('action: $action, ')
          ..write('amount: $amount, ')
          ..write('smsDate: $smsDate, ')
          ..write('smsReceivedDate: $smsReceivedDate, ')
          ..write('rawSmsBody: $rawSmsBody, ')
          ..write('createdAt: $createdAt, ')
          ..write('isManual: $isManual, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $TradesTable trades = $TradesTable(this);
  late final $FundTransfersTable fundTransfers = $FundTransfersTable(this);
  late final ChannelDao channelDao = ChannelDao(this as AppDatabase);
  late final TradeDao tradeDao = TradeDao(this as AppDatabase);
  late final FundTransferDao fundTransferDao = FundTransferDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    channels,
    trades,
    fundTransfers,
  ];
}

typedef $$ChannelsTableCreateCompanionBuilder =
    ChannelsCompanion Function({
      required String id,
      required String name,
      required String senderAddress,
      Value<String?> buyTemplate,
      Value<String?> sellTemplate,
      Value<String?> fundTemplate,
      Value<String> currency,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ChannelsTableUpdateCompanionBuilder =
    ChannelsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> senderAddress,
      Value<String?> buyTemplate,
      Value<String?> sellTemplate,
      Value<String?> fundTemplate,
      Value<String> currency,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $ChannelsTable, Channel> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TradesTable, List<Trade>> _tradesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.trades,
    aliasName: $_aliasNameGenerator(db.channels.id, db.trades.channelId),
  );

  $$TradesTableProcessedTableManager get tradesRefs {
    final manager = $$TradesTableTableManager(
      $_db,
      $_db.trades,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tradesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FundTransfersTable, List<FundTransfer>>
  _fundTransfersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fundTransfers,
    aliasName: $_aliasNameGenerator(db.channels.id, db.fundTransfers.channelId),
  );

  $$FundTransfersTableProcessedTableManager get fundTransfersRefs {
    final manager = $$FundTransfersTableTableManager(
      $_db,
      $_db.fundTransfers,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fundTransfersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderAddress => $composableBuilder(
    column: $table.senderAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyTemplate => $composableBuilder(
    column: $table.buyTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellTemplate => $composableBuilder(
    column: $table.sellTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fundTemplate => $composableBuilder(
    column: $table.fundTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tradesRefs(
    Expression<bool> Function($$TradesTableFilterComposer f) f,
  ) {
    final $$TradesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trades,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TradesTableFilterComposer(
            $db: $db,
            $table: $db.trades,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fundTransfersRefs(
    Expression<bool> Function($$FundTransfersTableFilterComposer f) f,
  ) {
    final $$FundTransfersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fundTransfers,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FundTransfersTableFilterComposer(
            $db: $db,
            $table: $db.fundTransfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderAddress => $composableBuilder(
    column: $table.senderAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyTemplate => $composableBuilder(
    column: $table.buyTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellTemplate => $composableBuilder(
    column: $table.sellTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fundTemplate => $composableBuilder(
    column: $table.fundTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get senderAddress => $composableBuilder(
    column: $table.senderAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get buyTemplate => $composableBuilder(
    column: $table.buyTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellTemplate => $composableBuilder(
    column: $table.sellTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fundTemplate => $composableBuilder(
    column: $table.fundTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> tradesRefs<T extends Object>(
    Expression<T> Function($$TradesTableAnnotationComposer a) f,
  ) {
    final $$TradesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trades,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TradesTableAnnotationComposer(
            $db: $db,
            $table: $db.trades,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fundTransfersRefs<T extends Object>(
    Expression<T> Function($$FundTransfersTableAnnotationComposer a) f,
  ) {
    final $$FundTransfersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fundTransfers,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FundTransfersTableAnnotationComposer(
            $db: $db,
            $table: $db.fundTransfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          Channel,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (Channel, $$ChannelsTableReferences),
          Channel,
          PrefetchHooks Function({bool tradesRefs, bool fundTransfersRefs})
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> senderAddress = const Value.absent(),
                Value<String?> buyTemplate = const Value.absent(),
                Value<String?> sellTemplate = const Value.absent(),
                Value<String?> fundTemplate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                name: name,
                senderAddress: senderAddress,
                buyTemplate: buyTemplate,
                sellTemplate: sellTemplate,
                fundTemplate: fundTemplate,
                currency: currency,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String senderAddress,
                Value<String?> buyTemplate = const Value.absent(),
                Value<String?> sellTemplate = const Value.absent(),
                Value<String?> fundTemplate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                name: name,
                senderAddress: senderAddress,
                buyTemplate: buyTemplate,
                sellTemplate: sellTemplate,
                fundTemplate: fundTemplate,
                currency: currency,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tradesRefs = false, fundTransfersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tradesRefs) db.trades,
                    if (fundTransfersRefs) db.fundTransfers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tradesRefs)
                        await $_getPrefetchedData<
                          Channel,
                          $ChannelsTable,
                          Trade
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._tradesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).tradesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fundTransfersRefs)
                        await $_getPrefetchedData<
                          Channel,
                          $ChannelsTable,
                          FundTransfer
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._fundTransfersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).fundTransfersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      Channel,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (Channel, $$ChannelsTableReferences),
      Channel,
      PrefetchHooks Function({bool tradesRefs, bool fundTransfersRefs})
    >;
typedef $$TradesTableCreateCompanionBuilder =
    TradesCompanion Function({
      required String id,
      required String channelId,
      required String action,
      required String symbol,
      required double quantity,
      required double price,
      required double totalValue,
      required DateTime smsDate,
      Value<DateTime?> smsReceivedDate,
      Value<String> rawSmsBody,
      Value<DateTime> createdAt,
      Value<bool> isManual,
      Value<bool> isEdited,
      Value<int> rowid,
    });
typedef $$TradesTableUpdateCompanionBuilder =
    TradesCompanion Function({
      Value<String> id,
      Value<String> channelId,
      Value<String> action,
      Value<String> symbol,
      Value<double> quantity,
      Value<double> price,
      Value<double> totalValue,
      Value<DateTime> smsDate,
      Value<DateTime?> smsReceivedDate,
      Value<String> rawSmsBody,
      Value<DateTime> createdAt,
      Value<bool> isManual,
      Value<bool> isEdited,
      Value<int> rowid,
    });

final class $$TradesTableReferences
    extends BaseReferences<_$AppDatabase, $TradesTable, Trade> {
  $$TradesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$AppDatabase db) => db.channels
      .createAlias($_aliasNameGenerator(db.trades.channelId, db.channels.id));

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<String>('channel_id')!;

    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TradesTableFilterComposer
    extends Composer<_$AppDatabase, $TradesTable> {
  $$TradesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalValue => $composableBuilder(
    column: $table.totalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get smsDate => $composableBuilder(
    column: $table.smsDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get smsReceivedDate => $composableBuilder(
    column: $table.smsReceivedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManual => $composableBuilder(
    column: $table.isManual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnFilters(column),
  );

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TradesTableOrderingComposer
    extends Composer<_$AppDatabase, $TradesTable> {
  $$TradesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalValue => $composableBuilder(
    column: $table.totalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get smsDate => $composableBuilder(
    column: $table.smsDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get smsReceivedDate => $composableBuilder(
    column: $table.smsReceivedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManual => $composableBuilder(
    column: $table.isManual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TradesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TradesTable> {
  $$TradesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get totalValue => $composableBuilder(
    column: $table.totalValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get smsDate =>
      $composableBuilder(column: $table.smsDate, builder: (column) => column);

  GeneratedColumn<DateTime> get smsReceivedDate => $composableBuilder(
    column: $table.smsReceivedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isManual =>
      $composableBuilder(column: $table.isManual, builder: (column) => column);

  GeneratedColumn<bool> get isEdited =>
      $composableBuilder(column: $table.isEdited, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TradesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TradesTable,
          Trade,
          $$TradesTableFilterComposer,
          $$TradesTableOrderingComposer,
          $$TradesTableAnnotationComposer,
          $$TradesTableCreateCompanionBuilder,
          $$TradesTableUpdateCompanionBuilder,
          (Trade, $$TradesTableReferences),
          Trade,
          PrefetchHooks Function({bool channelId})
        > {
  $$TradesTableTableManager(_$AppDatabase db, $TradesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TradesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TradesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TradesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<double> totalValue = const Value.absent(),
                Value<DateTime> smsDate = const Value.absent(),
                Value<DateTime?> smsReceivedDate = const Value.absent(),
                Value<String> rawSmsBody = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isManual = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TradesCompanion(
                id: id,
                channelId: channelId,
                action: action,
                symbol: symbol,
                quantity: quantity,
                price: price,
                totalValue: totalValue,
                smsDate: smsDate,
                smsReceivedDate: smsReceivedDate,
                rawSmsBody: rawSmsBody,
                createdAt: createdAt,
                isManual: isManual,
                isEdited: isEdited,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String channelId,
                required String action,
                required String symbol,
                required double quantity,
                required double price,
                required double totalValue,
                required DateTime smsDate,
                Value<DateTime?> smsReceivedDate = const Value.absent(),
                Value<String> rawSmsBody = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isManual = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TradesCompanion.insert(
                id: id,
                channelId: channelId,
                action: action,
                symbol: symbol,
                quantity: quantity,
                price: price,
                totalValue: totalValue,
                smsDate: smsDate,
                smsReceivedDate: smsReceivedDate,
                rawSmsBody: rawSmsBody,
                createdAt: createdAt,
                isManual: isManual,
                isEdited: isEdited,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TradesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable: $$TradesTableReferences
                                    ._channelIdTable(db),
                                referencedColumn: $$TradesTableReferences
                                    ._channelIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TradesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TradesTable,
      Trade,
      $$TradesTableFilterComposer,
      $$TradesTableOrderingComposer,
      $$TradesTableAnnotationComposer,
      $$TradesTableCreateCompanionBuilder,
      $$TradesTableUpdateCompanionBuilder,
      (Trade, $$TradesTableReferences),
      Trade,
      PrefetchHooks Function({bool channelId})
    >;
typedef $$FundTransfersTableCreateCompanionBuilder =
    FundTransfersCompanion Function({
      required String id,
      required String channelId,
      required String action,
      required double amount,
      required DateTime smsDate,
      Value<DateTime?> smsReceivedDate,
      Value<String> rawSmsBody,
      Value<DateTime> createdAt,
      Value<bool> isManual,
      Value<int> rowid,
    });
typedef $$FundTransfersTableUpdateCompanionBuilder =
    FundTransfersCompanion Function({
      Value<String> id,
      Value<String> channelId,
      Value<String> action,
      Value<double> amount,
      Value<DateTime> smsDate,
      Value<DateTime?> smsReceivedDate,
      Value<String> rawSmsBody,
      Value<DateTime> createdAt,
      Value<bool> isManual,
      Value<int> rowid,
    });

final class $$FundTransfersTableReferences
    extends BaseReferences<_$AppDatabase, $FundTransfersTable, FundTransfer> {
  $$FundTransfersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChannelsTable _channelIdTable(_$AppDatabase db) =>
      db.channels.createAlias(
        $_aliasNameGenerator(db.fundTransfers.channelId, db.channels.id),
      );

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<String>('channel_id')!;

    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FundTransfersTableFilterComposer
    extends Composer<_$AppDatabase, $FundTransfersTable> {
  $$FundTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get smsDate => $composableBuilder(
    column: $table.smsDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get smsReceivedDate => $composableBuilder(
    column: $table.smsReceivedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManual => $composableBuilder(
    column: $table.isManual,
    builder: (column) => ColumnFilters(column),
  );

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FundTransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $FundTransfersTable> {
  $$FundTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get smsDate => $composableBuilder(
    column: $table.smsDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get smsReceivedDate => $composableBuilder(
    column: $table.smsReceivedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManual => $composableBuilder(
    column: $table.isManual,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FundTransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FundTransfersTable> {
  $$FundTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get smsDate =>
      $composableBuilder(column: $table.smsDate, builder: (column) => column);

  GeneratedColumn<DateTime> get smsReceivedDate => $composableBuilder(
    column: $table.smsReceivedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isManual =>
      $composableBuilder(column: $table.isManual, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FundTransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FundTransfersTable,
          FundTransfer,
          $$FundTransfersTableFilterComposer,
          $$FundTransfersTableOrderingComposer,
          $$FundTransfersTableAnnotationComposer,
          $$FundTransfersTableCreateCompanionBuilder,
          $$FundTransfersTableUpdateCompanionBuilder,
          (FundTransfer, $$FundTransfersTableReferences),
          FundTransfer,
          PrefetchHooks Function({bool channelId})
        > {
  $$FundTransfersTableTableManager(_$AppDatabase db, $FundTransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FundTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FundTransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FundTransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> smsDate = const Value.absent(),
                Value<DateTime?> smsReceivedDate = const Value.absent(),
                Value<String> rawSmsBody = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isManual = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FundTransfersCompanion(
                id: id,
                channelId: channelId,
                action: action,
                amount: amount,
                smsDate: smsDate,
                smsReceivedDate: smsReceivedDate,
                rawSmsBody: rawSmsBody,
                createdAt: createdAt,
                isManual: isManual,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String channelId,
                required String action,
                required double amount,
                required DateTime smsDate,
                Value<DateTime?> smsReceivedDate = const Value.absent(),
                Value<String> rawSmsBody = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isManual = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FundTransfersCompanion.insert(
                id: id,
                channelId: channelId,
                action: action,
                amount: amount,
                smsDate: smsDate,
                smsReceivedDate: smsReceivedDate,
                rawSmsBody: rawSmsBody,
                createdAt: createdAt,
                isManual: isManual,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FundTransfersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable: $$FundTransfersTableReferences
                                    ._channelIdTable(db),
                                referencedColumn: $$FundTransfersTableReferences
                                    ._channelIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FundTransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FundTransfersTable,
      FundTransfer,
      $$FundTransfersTableFilterComposer,
      $$FundTransfersTableOrderingComposer,
      $$FundTransfersTableAnnotationComposer,
      $$FundTransfersTableCreateCompanionBuilder,
      $$FundTransfersTableUpdateCompanionBuilder,
      (FundTransfer, $$FundTransfersTableReferences),
      FundTransfer,
      PrefetchHooks Function({bool channelId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$TradesTableTableManager get trades =>
      $$TradesTableTableManager(_db, _db.trades);
  $$FundTransfersTableTableManager get fundTransfers =>
      $$FundTransfersTableTableManager(_db, _db.fundTransfers);
}
