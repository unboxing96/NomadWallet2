//
//  AddTravelView.swift
//  UMM
//
//  Created by GYURI PARK on 2023/10/10.
//

import SwiftUI

struct AddTravelView: View {

    @ObservedObject private var viewModel = AddTravelViewModel(month: Date())

    var body: some View {
        VStack {

            Spacer()

            headerView

            Spacer()

            VStack {
                calendarHeader
                calendarGridView
            }

            Spacer()
        }
    }

    private var headerView: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("기간을 입력해주세요")
                .font(.title)
                .fontWeight(.bold)

            Text("여행의 시작일과 종료일을 설정해주세요.")

            HStack {
                Text("시작일")
                Text("\(viewModel.startDate)" as String)
            }
        }
    }

    private var calendarHeader: some View {

        VStack(spacing: 30) {
            HStack {
                Button {
                    viewModel.changeMonth(by: -1)
                    print(Date())
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundStyle(Color.black)
                }

                Spacer()

                Text(viewModel.month, formatter: AddTravelViewModel.dateFormatter)
                    .font(.title)
                + Text("월")
                    .font(.title)

                Spacer()

                Button {
                    viewModel.changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .padding(1.0)
                        .font(.title)
                        .foregroundStyle(Color.black)
                }
            }
            .padding(.horizontal, 20)

            HStack {
                ForEach(AddTravelViewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var calendarGridView: some View {

        let daysInMonth: Int = viewModel.numberOfDays(in: viewModel.month)
        let firstWeekday: Int = viewModel.firstWeekdayOfMonth(in: viewModel.month) - 1

        return VStack {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(0 ..< daysInMonth + firstWeekday, id: \.self) { index in
                    if index < firstWeekday {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(.gray)
                    } else {
                        let date = viewModel.getDate(for: index - firstWeekday + 1)
                        let day = index - firstWeekday + 1
                        CellView(day: day, viewModel: viewModel, date: date)
                    }
                }
            }
        }
    }

    private struct CellView: View {

        private var day: Int
        private var date: Date?

        @ObservedObject private var viewModel: AddTravelViewModel

        init(day: Int, viewModel: AddTravelViewModel, date: Date?) {
            self.day = day
            self.viewModel = viewModel
            self.date = date
        }

        var body: some View {
            VStack {
                Button {
                    viewModel.startDate = date
                } label: {
                    Circle()
                        .opacity(0)
                        .overlay(Text(String(day)))
                        .foregroundStyle(Color.black)
                }
            }
        }
    }
}

#Preview {
    AddTravelView()
}