import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/core/services/template_parser.dart';
import 'channel_event.dart';
import 'channel_state.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final ChannelDao _channelDao;
  static const _uuid = Uuid();

  ChannelBloc({required ChannelDao channelDao})
      : _channelDao = channelDao,
        super(ChannelInitial()) {
    on<LoadChannels>(_onLoadChannels);
    on<AddChannel>(_onAddChannel);
    on<UpdateChannel>(_onUpdateChannel);
    on<DeleteChannel>(_onDeleteChannel);
    on<TestTemplate>(_onTestTemplate);
  }

  Future<void> _onLoadChannels(
    LoadChannels event,
    Emitter<ChannelState> emit,
  ) async {
    emit(ChannelLoading());
    try {
      final channels = await _channelDao.getAllChannels();
      emit(ChannelsLoaded(channels));
    } catch (e) {
      emit(ChannelError('Failed to load channels: $e'));
    }
  }

  Future<void> _onAddChannel(
    AddChannel event,
    Emitter<ChannelState> emit,
  ) async {
    try {
      final now = DateTime.now();
      await _channelDao.insertChannel(ChannelsCompanion.insert(
        id: _uuid.v4(),
        name: event.name,
        senderAddress: event.senderAddress,
        buyTemplate: Value(event.buyTemplate),
        sellTemplate: Value(event.sellTemplate),
        fundTemplate: Value(event.fundTemplate),
        currency: Value(event.currency),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      emit(const ChannelOperationSuccess('Channel added successfully'));
      add(LoadChannels());
    } catch (e) {
      emit(ChannelError('Failed to add channel: $e'));
    }
  }

  Future<void> _onUpdateChannel(
    UpdateChannel event,
    Emitter<ChannelState> emit,
  ) async {
    try {
      final existing = await _channelDao.getChannelById(event.id);
      if (existing == null) {
        emit(const ChannelError('Channel not found'));
        return;
      }

      await _channelDao.updateChannel(ChannelsCompanion(
        id: Value(event.id),
        name: Value(event.name),
        senderAddress: Value(event.senderAddress),
        buyTemplate: Value(event.buyTemplate),
        sellTemplate: Value(event.sellTemplate),
        fundTemplate: Value(event.fundTemplate),
        currency: Value(event.currency),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(DateTime.now()),
      ));
      emit(const ChannelOperationSuccess('Channel updated successfully'));
      add(LoadChannels());
    } catch (e) {
      emit(ChannelError('Failed to update channel: $e'));
    }
  }

  Future<void> _onDeleteChannel(
    DeleteChannel event,
    Emitter<ChannelState> emit,
  ) async {
    try {
      await _channelDao.deleteChannel(event.id);
      emit(const ChannelOperationSuccess('Channel deleted'));
      add(LoadChannels());
    } catch (e) {
      emit(ChannelError('Failed to delete channel: $e'));
    }
  }

  void _onTestTemplate(
    TestTemplate event,
    Emitter<ChannelState> emit,
  ) {
    try {
      final parser = TemplateParser(event.template);
      final result = parser.parse(event.sampleSms, smsReceivedDate: DateTime.now());
      emit(TemplateTestResult(
        matched: result.matched,
        result: result,
        regexPattern: parser.regexPattern,
      ));
    } catch (e) {
      emit(ChannelError('Template error: $e'));
    }
  }
}
