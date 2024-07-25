import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tempbox/bloc/data/data_bloc.dart';
import 'package:tempbox/bloc/data/data_event.dart';
import 'package:tempbox/bloc/data/data_state.dart';
import 'package:tempbox/models/address_data.dart';
import 'package:tempbox/services/alert_service.dart';
import 'package:tempbox/services/overlay_service.dart';
import 'package:tempbox/services/ui_service.dart';
import 'package:tempbox/shared/components/card_list_tile.dart';
import 'package:tempbox/android_views/address_info/address_info.dart';
import 'package:tempbox/android_views/messages_list/messages_list.dart';

class AddressTile extends StatelessWidget {
  final AddressData addressData;
  final bool isFirst;
  final bool isLast;
  const AddressTile({super.key, required this.addressData, required this.isFirst, required this.isLast});

  _openAddressInfoSheet(BuildContext context, BuildContext dataBlocContext, AddressData addressData) {
    OverlayService.showOverLay(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      enableDrag: true,
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<DataBloc>(dataBlocContext),
        child: AddressInfo(addressData: addressData),
      ),
    );
  }

  _navigateToMessagesList(BuildContext context, BuildContext dataBlocContext, AddressData addressData) {
    BlocProvider.of<DataBloc>(dataBlocContext).add(SelectAddressEvent(addressData));
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<DataBloc>(dataBlocContext),
        child: const MessagesList(),
      ),
    ));
  }

  _deleteAddress(BuildContext context, BuildContext dataBlocContext, AddressData addressData) async {
    bool? choice = await AlertService.getConformation(
      context: context,
      title: 'Alert',
      content: 'Are you sure you want to delete this address?',
    );
    if (choice == true && dataBlocContext.mounted) {
      BlocProvider.of<DataBloc>(dataBlocContext).add(DeleteAddressEvent(addressData));
    }
  }

  _toggleArchiveAddress(BuildContext context, BuildContext dataBlocContext, AddressData addressData) async {
    String alertMessage = 'Are you sure you want to archive this address?';
    if (!addressData.isActive) {
      alertMessage = 'Are you sure you want to activate this address?';
    }
    bool? choice = await AlertService.getConformation(context: context, title: 'Alert', content: alertMessage);
    if (choice == true && dataBlocContext.mounted) {
      if (!addressData.isActive) {
        BlocProvider.of<DataBloc>(dataBlocContext).add(UnarchiveAddressEvent(addressData));
        return;
      }
      BlocProvider.of<DataBloc>(dataBlocContext).add(ArchiveAddressEvent(addressData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataBloc, DataState>(builder: (dataBlocContext, dataState) {
      String messageCount = (dataState.accountIdToAddressesMap[addressData.authenticatedUser.account.id]?.length ?? 0).toString();
      return CardListTile(
        isFirst: isFirst,
        isLast: isLast,
        child: Slidable(
          groupTag: 'AddressItem',
          key: ValueKey(addressData.authenticatedUser.account.id),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _openAddressInfoSheet(context, dataBlocContext, addressData),
                backgroundColor: Colors.amber,
                // backgroundColor: const Color(0XFFFED709),
                foregroundColor: Colors.white,
                icon: Icons.info_rounded,
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _toggleArchiveAddress(context, dataBlocContext, addressData),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                icon: addressData.isActive ? Icons.archive_rounded : Icons.unarchive_rounded,
              ),
              SlidableAction(
                onPressed: (_) => _deleteAddress(context, dataBlocContext, addressData),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline_outlined,
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(Icons.inbox_rounded, color: Theme.of(context).buttonTheme.colorScheme?.primary ?? Colors.red),
            title: Text(UiService.getAccountName(addressData)),
            trailing: SizedBox(
              width: messageCount.length == 1
                  ? 25
                  : messageCount.length == 2
                      ? 32
                      : 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(messageCount),
                  const Icon(Icons.chevron_right, size: 17),
                ],
              ),
            ),
            onTap: () => _navigateToMessagesList(context, dataBlocContext, addressData),
          ),
        ),
      );
    });
  }
}
