import 'package:flutter/material.dart';
class BusSecretaryDashboard1 extends StatefulWidget {
	const BusSecretaryDashboard1({super.key});
	@override
		BusSecretaryDashboard1State createState() => BusSecretaryDashboard1State();
	}
class BusSecretaryDashboard1State extends State<BusSecretaryDashboard1> {
	String textField1 = '';
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: Color(0xFFFFFFFF),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: IntrinsicHeight(
									child: Container(
										color: Color(0xFFFFFFFF),
										width: double.infinity,
										height: double.infinity,
										child: SingleChildScrollView(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 29),
															width: double.infinity,
															child: Stack(
																clipBehavior: Clip.none,
																children: [
																	Padding(
																		padding: const EdgeInsets.only( left: 25, right: 25),
																		child: Column(
																			crossAxisAlignment: CrossAxisAlignment.start,
																			children: [
																				IntrinsicHeight(
																					child: Container(
																						decoration: BoxDecoration(
																							borderRadius: BorderRadius.circular(14),
																							color: Color(0xFF154C77),
																						),
																						padding: const EdgeInsets.only( left: 33, right: 33),
																						margin: const EdgeInsets.only( top: 114),
																						width: double.infinity,
																						child: Column(
																							crossAxisAlignment: CrossAxisAlignment.start,
																							children: [
																								IntrinsicHeight(
																									child: Container(
																										decoration: BoxDecoration(
																											borderRadius: BorderRadius.circular(14),
																											color: Color(0xFFFFFFFF),
																										),
																										padding: const EdgeInsets.only( left: 13),
																										margin: const EdgeInsets.only( top: 42, bottom: 27),
																										width: double.infinity,
																										child: Column(
																											crossAxisAlignment: CrossAxisAlignment.start,
																											children: [
																												Container(
																													margin: const EdgeInsets.only( top: 24, bottom: 13),
																													child: Text(
																														"ROLE SELECTED",
																														style: TextStyle(
																															color: Color(0xFF000000),
																															fontSize: 20,
																														),
																													),
																												),
																											]
																										),
																									),
																								),
																								IntrinsicHeight(
																									child: Container(
																										alignment: Alignment.center,
																										decoration: BoxDecoration(
																											borderRadius: BorderRadius.circular(14),
																											color: Color(0xFFFFFFFF),
																										),
																										margin: const EdgeInsets.only( bottom: 64),
																										width: double.infinity,
																										child: TextField(
																											style: TextStyle(
																												color: Color(0xFF000000),
																												fontSize: 20,
																											),
																											onChanged: (value) { 
																												setState(() { textField1 = value; });
																											},
																											decoration: InputDecoration(
																												hintText: "ROUTE ASSSIGNED",
																												isDense: true,
																												contentPadding: const EdgeInsets.only( top: 18, bottom: 18, left: 14, right: 14),
																												border: InputBorder.none,
																												focusedBorder: InputBorder.none,
																												filled: false,
																											),
																										),
																									),
																								),
																							]
																						),
																					),
																				),
																			]
																		),
																	),
																	Positioned(
																		top: 0,
																		left: 0,
																		width: 183,
																		height: 140,
																		child: Container(
																			width: 183,
																			height: 140,
																			child: Image.network(
																				"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/bv2yaeqs_expires_30_days.png",
																				fit: BoxFit.fill,
																			)
																		),
																	),
																	Positioned(
																		top: 0,
																		left: 0,
																		right: 0,
																		child: IntrinsicHeight(
																			child: Container(
																				color: Color(0xFF193D59),
																				padding: const EdgeInsets.only( top: 11, bottom: 11, left: 1, right: 24),
																				width: double.infinity,
																				child: Column(
																					crossAxisAlignment: CrossAxisAlignment.start,
																					children: [
																						IntrinsicHeight(
																							child: Container(
																								width: double.infinity,
																								child: Row(
																									crossAxisAlignment: CrossAxisAlignment.start,
																									children: [
																										Container(
																											margin: const EdgeInsets.only( right: 16),
																											width: 24,
																											height: 24,
																											child: Image.network(
																												"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/92lfjlqd_expires_30_days.png",
																												fit: BoxFit.fill,
																											)
																										),
																										Container(
																											decoration: BoxDecoration(
																												borderRadius: BorderRadius.circular(10),
																												color: Color(0xFFFFFFFF),
																											),
																											margin: const EdgeInsets.only( top: 12),
																											width: 76,
																											height: 66,
																											child: SizedBox(),
																										),
																										Expanded(
																											child: Container(
																												width: double.infinity,
																												child: SizedBox(),
																											),
																										),
																										IntrinsicWidth(
																											child: IntrinsicHeight(
																												child: Container(
																													decoration: BoxDecoration(
																														borderRadius: BorderRadius.circular(10),
																														color: Color(0xFFFFFFFF),
																													),
																													padding: const EdgeInsets.only( top: 6, left: 8, right: 8),
																													margin: const EdgeInsets.only( top: 29),
																													child: Column(
																														crossAxisAlignment: CrossAxisAlignment.start,
																														children: [
																															Container(
																																width: 33,
																																height: 43,
																																child: Image.network(
																																	"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/o0nyf4it_expires_30_days.png",
																																	fit: BoxFit.fill,
																																)
																															),
																														]
																													),
																												),
																											),
																										),
																									]
																								),
																							),
																						),
																					]
																				),
																			),
																		),
																	),
																]
															),
														),
													),
													InkWell(
														onTap: () { print('Pressed'); },
														child: IntrinsicHeight(
															child: Container(
																decoration: BoxDecoration(
																	borderRadius: BorderRadius.circular(17),
																	color: Color(0xFF154C77),
																),
																padding: const EdgeInsets.symmetric(vertical: 15),
																margin: const EdgeInsets.only( bottom: 27, left: 30, right: 30),
																width: double.infinity,
																child: Column(
																	children: [
																		Text(
																			"USER MANAGEMENT",
																			style: TextStyle(
																				color: Color(0xFFFFFFFF),
																				fontSize: 24,
																			),
																		),
																	]
																),
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																borderRadius: BorderRadius.circular(14),
																color: Color(0xFF154C77),
															),
															padding: const EdgeInsets.only( top: 22, bottom: 22, left: 16, right: 16),
															margin: const EdgeInsets.only( bottom: 13, left: 25, right: 25),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	InkWell(
																		onTap: () { print('Pressed'); },
																		child: IntrinsicHeight(
																			child: Container(
																				decoration: BoxDecoration(
																					borderRadius: BorderRadius.circular(17),
																					color: Color(0xFFFFFFFF),
																				),
																				padding: const EdgeInsets.symmetric(vertical: 67),
																				margin: const EdgeInsets.only( bottom: 21),
																				width: double.infinity,
																				child: Column(
																					children: [
																						Text(
																							"MAP_VIEW",
																							style: TextStyle(
																								color: Color(0xFF000000),
																								fontSize: 12,
																							),
																						),
																					]
																				),
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			width: double.infinity,
																			child: Row(
																				crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					Expanded(
																						child: InkWell(
																							onTap: () { print('Pressed'); },
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(17),
																										color: Color(0xFFFFFFFF),
																									),
																									padding: const EdgeInsets.symmetric(vertical: 55),
																									margin: const EdgeInsets.only( right: 26),
																									width: double.infinity,
																									child: Column(
																										children: [
																											Text(
																												"BUS PASS FEE",
																												style: TextStyle(
																													color: Color(0xFF000000),
																													fontSize: 14,
																												),
																											),
																										]
																									),
																								),
																							),
																						),
																					),
																					Expanded(
																						child: Container(
																							decoration: BoxDecoration(
																								borderRadius: BorderRadius.circular(17),
																								color: Color(0xFFFFFFFF),
																							),
																							height: 130,
																							width: double.infinity,
																							child: SizedBox(),
																						),
																					),
																				]
																			),
																		),
																	),
																]
															),
														),
													),
												],
											)
										),
									),
								),
							),
						],
					),
				),
			),
		);
	}
}