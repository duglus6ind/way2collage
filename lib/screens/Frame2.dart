import 'package:flutter/material.dart';
class Frame2 extends StatefulWidget {
	const Frame2({super.key});
	@override
		Frame2State createState() => Frame2State();
	}
class Frame2State extends State<Frame2> {
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
										width: double.infinity,
										height: double.infinity,
										child: SingleChildScrollView(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															color: Color(0xFFFFFFFF),
															margin: const EdgeInsets.only( bottom: 12),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( bottom: 33),
																			width: double.infinity,
																			child: Stack(
																				clipBehavior: Clip.none,
																				children: [
																					Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							IntrinsicHeight(
																								child: Container(
																									color: Color(0xFF0D2726),
																									width: double.infinity,
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Container(
																												margin: const EdgeInsets.only( bottom: 14, left: 1),
																												width: 24,
																												height: 24,
																												child: Image.network(
																													"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/7fsdlos5_expires_30_days.png",
																													fit: BoxFit.fill,
																												)
																											),
																											IntrinsicHeight(
																												child: Container(
																													margin: const EdgeInsets.only( bottom: 13),
																													width: double.infinity,
																													child: Column(
																														crossAxisAlignment: CrossAxisAlignment.end,
																														children: [
																															InkWell(
																																onTap: () { print('Pressed'); },
																																child: IntrinsicWidth(
																																	child: IntrinsicHeight(
																																		child: Container(
																																			decoration: BoxDecoration(
																																				borderRadius: BorderRadius.circular(10),
																																				color: Color(0xFFFFFFFF),
																																			),
																																			padding: const EdgeInsets.only( top: 4, bottom: 4, left: 5, right: 5),
																																			margin: const EdgeInsets.only( right: 24),
																																			child: Column(
																																				crossAxisAlignment: CrossAxisAlignment.start,
																																				children: [
																																					Container(
																																						width: 40,
																																						height: 40,
																																						child: Image.network(
																																							"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/l2o6lugq_expires_30_days.png",
																																							fit: BoxFit.fill,
																																						)
																																					),
																																				]
																																			),
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
																						]
																					),
																					Positioned(
																						bottom: 0,
																						left: 14,
																						width: 96,
																						height: 96,
																						child: Container(
																							transform: Matrix4.translationValues(0, 5, 0),
																							width: 96,
																							height: 96,
																							child: Image.network(
																								"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/8aerbf9h_expires_30_days.png",
																								fit: BoxFit.fill,
																							)
																						),
																					),
																				]
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			decoration: BoxDecoration(
																				borderRadius: BorderRadius.circular(14),
																				color: Color(0xFF144947),
																			),
																			margin: const EdgeInsets.only( bottom: 50, left: 25, right: 25),
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
																							padding: const EdgeInsets.only( top: 26, bottom: 26, left: 48),
																							margin: const EdgeInsets.only( top: 17, bottom: 35, left: 24, right: 24),
																							width: double.infinity,
																							child: Column(
																								crossAxisAlignment: CrossAxisAlignment.start,
																								children: [
																									Text(
																										"ROUTE SELECTED",
																										style: TextStyle(
																											color: Color(0xFF000000),
																											fontSize: 20,
																										),
																									),
																								]
																							),
																						),
																					),
																					Container(
																						color: Color(0xFFFFFFFF),
																						margin: const EdgeInsets.only( bottom: 15, left: 30, right: 30),
																						height: 24,
																						width: double.infinity,
																						child: SizedBox(),
																					),
																					Container(
																						color: Color(0xFFFFFFFF),
																						margin: const EdgeInsets.only( bottom: 56, left: 30, right: 30),
																						height: 24,
																						width: double.infinity,
																						child: SizedBox(),
																					),
																				]
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			decoration: BoxDecoration(
																				borderRadius: BorderRadius.circular(14),
																				color: Color(0xFFD9D9D9),
																			),
																			margin: const EdgeInsets.only( bottom: 57, left: 25, right: 25),
																			width: double.infinity,
																			child: Column(
																				crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					IntrinsicHeight(
																						child: Container(
																							margin: const EdgeInsets.only( top: 120, bottom: 119),
																							width: double.infinity,
																							child: Column(
																								children: [
																									Text(
																										"map_view",
																										style: TextStyle(
																											color: Color(0xFF000000),
																											fontSize: 12,
																										),
																									),
																								]
																							),
																						),
																					),
																					InkWell(
																						onTap: () { print('Pressed'); },
																						child: IntrinsicWidth(
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(47),
																										color: Color(0xFF154947),
																									),
																									padding: const EdgeInsets.only( top: 25, bottom: 25, left: 74, right: 74),
																									margin: const EdgeInsets.only( bottom: 41, left: 49),
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Text(
																												"BUS STATUS",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 20,
																												),
																											),
																										]
																									),
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
													IntrinsicHeight(
														child: Container(
															color: Color(0xFFFFFFFF),
															padding: const EdgeInsets.symmetric(vertical: 43),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( bottom: 120, left: 26, right: 26),
																			width: double.infinity,
																			child: Stack(
																				clipBehavior: Clip.none,
																				children: [
																					Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(14),
																										color: Color(0xFF154947),
																									),
																									padding: const EdgeInsets.symmetric(vertical: 29),
																									width: double.infinity,
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											IntrinsicHeight(
																												child: Container(
																													margin: const EdgeInsets.only( bottom: 16, left: 21, right: 21),
																													width: double.infinity,
																													child: Stack(
																														clipBehavior: Clip.none,
																														children: [
																															Column(
																																crossAxisAlignment: CrossAxisAlignment.start,
																																children: [
																																	InkWell(
																																		onTap: () { print('Pressed'); },
																																		child: IntrinsicHeight(
																																			child: Container(
																																				decoration: BoxDecoration(
																																					borderRadius: BorderRadius.circular(14),
																																					color: Color(0xFFFFFFFF),
																																				),
																																				padding: const EdgeInsets.symmetric(vertical: 55),
																																				width: double.infinity,
																																				child: Column(
																																					children: [
																																						Text(
																																							"BUS PASS",
																																							style: TextStyle(
																																								color: Color(0xFF000000),
																																								fontSize: 24,
																																							),
																																						),
																																					]
																																				),
																																			),
																																		),
																																	),
																																]
																															),
																															Positioned(
																																top: 29,
																																right: 0,
																																width: 49,
																																height: 49,
																																child: Container(
																																	decoration: BoxDecoration(
																																		borderRadius: BorderRadius.circular(10),
																																		color: Color(0xFFFFFFFF),
																																	),
																																	transform: Matrix4.translationValues(18, 0, 0),
																																	width: 49,
																																	height: 49,
																																	child: SizedBox(),
																																),
																															),
																														]
																													),
																												),
																											),
																											IntrinsicHeight(
																												child: Container(
																													decoration: BoxDecoration(
																														borderRadius: BorderRadius.circular(31),
																														color: Color(0xFFFFFFFF),
																													),
																													padding: const EdgeInsets.only( top: 21, bottom: 21, left: 50),
																													margin: const EdgeInsets.symmetric(horizontal: 30),
																													width: double.infinity,
																													child: Column(
																														crossAxisAlignment: CrossAxisAlignment.start,
																														children: [
																															Text(
																																"APPLY FOR BUS PASS",
																																style: TextStyle(
																																	color: Color(0xFF000000),
																																	fontSize: 16,
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
																						]
																					),
																					Positioned(
																						top: 47,
																						left: 0,
																						width: 78,
																						height: 64,
																						child: Container(
																							decoration: BoxDecoration(
																								borderRadius: BorderRadius.circular(10),
																								color: Color(0xFFFFFFFF),
																							),
																							transform: Matrix4.translationValues(-6, 0, 0),
																							width: 78,
																							height: 64,
																							child: SizedBox(),
																						),
																					),
																				]
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			decoration: BoxDecoration(
																				borderRadius: BorderRadius.circular(14),
																				color: Color(0xFF154947),
																			),
																			padding: const EdgeInsets.only( left: 39, right: 39),
																			margin: const EdgeInsets.symmetric(horizontal: 25),
																			width: double.infinity,
																			child: Column(
																				crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					InkWell(
																						onTap: () { print('Pressed'); },
																						child: IntrinsicHeight(
																							child: Container(
																								decoration: BoxDecoration(
																									borderRadius: BorderRadius.circular(47),
																									color: Color(0xFFFFFFFF),
																								),
																								padding: const EdgeInsets.symmetric(vertical: 28),
																								margin: const EdgeInsets.only( top: 72, bottom: 46),
																								width: double.infinity,
																								child: Column(
																									children: [
																										Text(
																											"SEAT AVAILABILITY",
																											style: TextStyle(
																												color: Color(0xFF000000),
																												fontSize: 15,
																											),
																										),
																									]
																								),
																							),
																						),
																					),
																					InkWell(
																						onTap: () { print('Pressed'); },
																						child: IntrinsicHeight(
																							child: Container(
																								decoration: BoxDecoration(
																									borderRadius: BorderRadius.circular(47),
																									color: Color(0xFFFFFFFF),
																								),
																								padding: const EdgeInsets.symmetric(vertical: 28),
																								margin: const EdgeInsets.only( bottom: 45),
																								width: double.infinity,
																								child: Column(
																									children: [
																										Text(
																											"LOST AND FOUND",
																											style: TextStyle(
																												color: Color(0xFF000000),
																												fontSize: 16,
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