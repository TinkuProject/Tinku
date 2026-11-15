import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../helpers/media_helper.dart';

class UserAvatar extends StatelessWidget {
  final double radius;

  const UserAvatar({
    super.key,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    final imageUrl =
    MediaHelper.getPrimaryUrl(user?.media ?? []);

    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl != null
          ? NetworkImage(imageUrl)
          : const AssetImage('assets/icons/defaultUser.jpg')
      as ImageProvider,
    );
  }
}