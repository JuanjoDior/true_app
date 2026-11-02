import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import 'dossier_body_keys.dart';

class DossierFooter extends StatelessWidget {
  const DossierFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= DsBreakpoints.desktop;
    return Container(
      key: DossierBodyKeys.footer,
      margin: const EdgeInsets.only(top: DsSpacing.s80),
      padding: EdgeInsets.symmetric(
        horizontal: wide ? DsSpacing.pageMarginDesktop : DsSpacing.pageMarginMobile,
        vertical: DsSpacing.s40,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DsColors.lineHairline)),
      ),
      child: Wrap(
        spacing: DsSpacing.s40,
        runSpacing: DsSpacing.s16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('TRUE', style: DsTextStyles.desktop.displayPoster),
          Text(
            'Crímenes reales · documentados con respeto. Las víctimas se nombran con respeto.',
            style: DsTextStyles.desktop.body.copyWith(color: DsColors.textFaint),
          ),
        ],
      ),
    );
  }
}
