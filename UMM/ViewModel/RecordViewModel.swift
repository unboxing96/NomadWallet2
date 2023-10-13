//
//  RecordViewModel.swift
//  UMM
//
//  Created by Wonil Lee on 10/12/23.
//

import Foundation

final class RecordViewModel: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    @Published var voiceSentence: String = RecordViewModel.voiceSentenceArray[0]
    @Published var info: String?
    @Published var infoCategory: ExpenseInfoCategory = .unknown
    @Published var payAmount: Double = -1
    @Published var paymentMethod: PaymentMethod = .unknown
    
    static let voiceSentenceArray = [
        "",
        "하얀 요트 십 팔만 1,300 점이오달 러",
        "3.25달러",
        "1,000,000루피",
        "세면도구 3000루피",
        "100,000,000 50,000,000루피",
        "2000페소 사토시",
        "150 솔",
        "250,000 Sol",
        "500 헤알",
        "점 육 오",
        "190.65",
        "30,000루블 카드",
        "330,000,025.35달러",
        "3,000,000,000",
        "오만 오천동",
        "삼만 이 백동",
        "3.25",
        "안녕하세요",
        "오로나민씨 2000원",
        "오이 3000원"
    ]
    var voiceSentenceChoicer: Int = 0
    
    func divideVoiceSentence() {
        guard voiceSentence.count > 0 else {
            info = nil
            payAmount = -1
            paymentMethod = .unknown
            return
        }
        
        // MARK: - 전체 스트링을 스페이스바 기준으로 스플릿
        
        var splitArray = voiceSentence.components(separatedBy: " ")
        var formSplitArray: [[CharacterForm]] {
            var temp = [[CharacterForm]]()
            for i in 0..<splitArray.count {
                temp.append(splitArray[i].getCharacterFormArray())
            }
            return temp
        }
        var splitVarietyAndCountArray: [(SplitVariety, Int)] {
            var temp = [(SplitVariety, Int)]()
            let localFormSplitArray = formSplitArray
            for i in 0..<splitArray.count {
                temp.append(localFormSplitArray[i].getSplitVarietyAndNumericPrefixCount())
            }
            return temp
        }
        
        // MARK: - 쉼표 없애기
        
        for i in 0..<splitArray.count {
            var j = splitArray[i].endIndex
            for _ in (0..<splitArray[i].count).reversed() {
                j = splitArray[i].index(before: j)
                if splitArray[i][j] == "," {
                    splitArray[i].remove(at: j)
                }
            }
        }
        
        // MARK: - (카드, 현금, 카드로, 현금으로, 카드 결제, 현금 결제) 중 하나로 끝나면 그 부분 remove하고 카드 혹은 현금을 인식해서 paymentMethod 변수에 입력
        
        if let last = splitArray.last {
            if last == "카드" || last == "카드로" || last == "카드결제" {
                paymentMethod = .card
                splitArray.removeLast()
            } else if last == "현금" || last == "현금으로" || last == "현금결제" {
                paymentMethod = .cash
                splitArray.removeLast()
            } else if last == "결제" && splitArray.count > 1 {
                let beforeLast = splitArray[splitArray.count - 2]
                if beforeLast == "카드" || beforeLast == "카드로" {
                    paymentMethod = .card
                    splitArray.removeLast()
                    splitArray.removeLast()
                } else if beforeLast == "현금" || beforeLast == "현금으로" {
                    paymentMethod = .cash
                    splitArray.removeLast()
                    splitArray.removeLast()
                }
            } else {
                paymentMethod = .unknown
            }
        }
        
        guard splitArray.count > 0 else {
            info = nil
            payAmount = -1
            return
        }
        
        // MARK: - 숫자로 해석할 조각(split)이 없으면 전부 info에 넣고 끝내기
        
        var allNoNumericInterpretation = true
        var tempSplitVarietyAndCountArray = splitVarietyAndCountArray
        for splitVariety in tempSplitVarietyAndCountArray where splitVariety.0 != .noNumericInterpretation {
            allNoNumericInterpretation = false
            break
        }
        if allNoNumericInterpretation {
            info = splitArray.getUnifiedStringWithSpaceBetweenEachSplit()
            payAmount = -1
            return
        }
        
        // MARK: - 뒤에서부터 조각을 읽고, 숫자로 해석 안 되는 연속된 조각 전부 없애기
        
        var indexing = 0
        while indexing < tempSplitVarietyAndCountArray.count && tempSplitVarietyAndCountArray[tempSplitVarietyAndCountArray.count - indexing - 1].0 == .noNumericInterpretation {
            splitArray.removeLast()
            indexing += 1
        }
        
        // MARK: - 가장 마지막 조각이 .startsWithNumeric이면 뉴메릭 아닌 부분은 잘라내서 없애기
        
        if indexing > 0 {
            tempSplitVarietyAndCountArray = splitVarietyAndCountArray
        }
        
        if tempSplitVarietyAndCountArray.last!.0 == .startsWithNumeric {
            var temp = splitArray.removeLast()
            temp =
            String(temp.prefix(tempSplitVarietyAndCountArray.last!.1))
            splitArray.append(temp)
            tempSplitVarietyAndCountArray = splitVarietyAndCountArray
        }
        
        // MARK: - 뒤에서부터 조각을 읽고, 숫자로 이해되는 연속된 조각들을 변환해서 payAmount로 넘기기
        
        // 1. 뒤에서의 연속된 뉴메릭 스플릿들을 별도의 단일 문자형 스트링 어레이로 떼어놓기
        
        var numberOfAllNumericSplits = 0
        while numberOfAllNumericSplits < tempSplitVarietyAndCountArray.count && tempSplitVarietyAndCountArray[tempSplitVarietyAndCountArray.count - numberOfAllNumericSplits - 1].0 == .allNumeric {
            numberOfAllNumericSplits += 1
        }
        
        var numericSplits: [String] = []
        
        for i in (splitArray.count - numberOfAllNumericSplits)..<splitArray.count {
            numericSplits.append(splitArray[i])
        }
        
        splitArray = [String](splitArray[0..<(splitArray.count - numberOfAllNumericSplits)])
        
        var monoNumericArray: [String] = []
        
        for split in numericSplits {
            let tempMono = split.unicodeScalars.map(String.init)
            monoNumericArray += tempMono
            monoNumericArray.append(" ")
        }
        
        guard monoNumericArray.count > 0 else {
            info = splitArray.getUnifiedStringWithSpaceBetweenEachSplit()
            payAmount = -1
            return
        }
        
        // 2. "점", "." 가장 빠른 하나만 남기고 없애기, "만" 또한 가장 빠른 그리고 점보다 빠른 하나만 남기고 없애기
        
        let arabicDotIndex = monoNumericArray.firstIndex(of: ".")
        let koreanDotIndex = monoNumericArray.firstIndex(of: "점")
        
        var dotIndex: Int? = min(Int(arabicDotIndex ?? Int.max), Int(koreanDotIndex ?? Int.max))
        if dotIndex == Int.max {
            dotIndex = nil
        }
        
        monoNumericArray = monoNumericArray.filter { $0 != "." && $0 != "점" }
        
        if let dotIndex, dotIndex <= monoNumericArray.count {
            monoNumericArray.insert(".", at: dotIndex)
        }
        
        var fourPowerIndex: Int? = Int(monoNumericArray.firstIndex(of: "만") ?? Int.max)
        if fourPowerIndex == Int.max {
            fourPowerIndex = nil
        }
        
        monoNumericArray = monoNumericArray.filter { $0 != "만"}
        
        dotIndex = Int(monoNumericArray.firstIndex(of: ".") ?? Int.max)
        if dotIndex == Int.max {
            dotIndex = nil
        }
        
        if let fourPowerIndex, fourPowerIndex <= monoNumericArray.count {
            if dotIndex == nil {
                monoNumericArray.insert("만", at: fourPowerIndex)
            } else if let di = dotIndex {
                if fourPowerIndex <= di {
                    monoNumericArray.insert("만", at: fourPowerIndex)
                    dotIndex! += 1
                }
            }
        }
        
        // 3. "." 있으면 그것을 기준으로 앞(monoNumericArray)과 뒤(monoC)로 분리하기
        
        var monoA: [String] = []
        var monoB: [String] = []
        var monoC: [String] = []
        
        if let dotIndex {
            if dotIndex == monoNumericArray.count - 1 {
                monoNumericArray.removeLast()
            } else {
                monoC = [String](monoNumericArray[(dotIndex + 1)..<monoNumericArray.count])
                monoNumericArray = [String](monoNumericArray[0..<dotIndex])
            }
        }
        
        // 4. "만"이 있으면 그것을 기준으로 앞(monoA)과 뒤(monoB)로 분리하기. 세 덩어리(monoA, monoB, monoC)를 A, B, C라고 하자.
        
        if let fourPowerIndex {
            monoA = [String](monoNumericArray[0..<fourPowerIndex])
            monoB = [String](monoNumericArray[(fourPowerIndex + 1)..<monoNumericArray.count])
        } else {
            monoB = monoNumericArray
        }
        
        // 5. A, B 안에서 이어지는 아바리아 숫자 여러 개는 이어붙인 문자열 한 개로 대치하기
        
        if monoA.count > 1 {
            for i in (1..<monoA.count).reversed() {
                if let digit1 = monoA[i-1].first, let digit0 = monoA[i].first {
                    if digit1.getCharacterForm() == .arabicNumeric && digit0.getCharacterForm() == .arabicNumeric {
                        monoA[i-1] = String(digit1) + monoA[i]
                        monoA.remove(at: i)
                    }
                }
            }
        }
        
        if monoB.count > 1 {
            for i in (1..<monoB.count).reversed() {
                if let digit1 = monoB[i-1].first, let digit0 = monoB[i].first {
                    if digit1.getCharacterForm() == .arabicNumeric && digit0.getCharacterForm() == .arabicNumeric {
                        monoB[i-1] = String(digit1) + monoB[i]
                        monoB.remove(at: i)
                    }
                }
            }
        }
        
        // 6. A, B에서 공백 없애기
        
        for i in (0..<monoA.count).reversed() where monoA[i] == " " {
            monoA.remove(at: i)
        }
        
        for i in (0..<monoB.count).reversed() where monoB[i] == " " {
            monoB.remove(at: i)
        }
        
        // 7. C 안에서 arabicNumeric 혹은 koreanNumeric이 아닌 원소는 없애기
        
        if monoC.count > 1 {
            for i in (0..<monoC.count).reversed() {
                if let digit = monoC[i].first {
                    if digit.getCharacterForm() != .arabicNumeric && digit.getCharacterForm() != .koreanNumeric {
                        monoC.remove(at: i)
                    }
                }
            }
        }
        
        // 8. A에 10000보다 큰 수가 포함되어 있으면 sum에 더해주고 없애기
        
        var sum: Double = 0
        
        for i in (0..<monoA.count).reversed() where monoA[i].count > 4 {
            sum += Double(monoA[i]) ?? 0
            monoA.remove(at: i)
        }
        
        // 9. A, B에서 "천", "백", "십" 앞에 한글 숫자가 있으면 1000 100 10 곱해서 아라비아로 바꾸기, 없으면 그것을 1000, 100, 10으로 바꾸기
        
        if monoA.count > 1 {
            for i in (1..<monoA.count).reversed() {
                if monoA[i] == "십" {
                    if monoA[i-1].count == 1 && monoA[i-1].first!.getCharacterForm() == .koreanNumeric {
                        monoA[i-1] = "\((Int(monoA[i-1].first!.getCorrespondingArabicString()) ?? 0) * 10)"
                        monoA.remove(at: i)
                    } else {
                        monoA[i] = "10"
                    }
                } else if monoA[i] == "백" {
                    if monoA[i-1].count == 1 && monoA[i-1].first!.getCharacterForm() == .koreanNumeric {
                        monoA[i-1] = "\((Int(monoA[i-1].first!.getCorrespondingArabicString()) ?? 0) * 100)"
                        monoA.remove(at: i)
                    } else {
                        monoA[i] = "100"
                    }
                } else if monoA[i] == "천" {
                    if monoA[i-1].count == 1 && monoA[i-1].first!.getCharacterForm() == .koreanNumeric {
                        monoA[i-1] = "\((Int(monoA[i-1].first!.getCorrespondingArabicString()) ?? 0) * 1000)"
                        monoA.remove(at: i)
                    } else {
                        monoA[i] = "1000"
                    }
                }
            }
        }
        if monoA.count > 0 {
            if monoA[0] == "십" {
                monoA[0] = "10"
            } else if monoA[0] == "백" {
                monoA[0] = "100"
            } else if monoA[0] == "천" {
                monoA[0] = "1000"
            }
        }
        
        if monoB.count > 1 {
            for i in (1..<monoB.count).reversed() {
                if monoB[i] == "십" {
                    if monoB[i-1].count == 1 && monoB[i-1].first!.getCharacterForm() == .koreanNumeric {
                        monoB[i-1] = "\((Int(monoB[i-1].first!.getCorrespondingArabicString()) ?? 0) * 10)"
                        monoB.remove(at: i)
                    } else {
                        monoB[i] = "10"
                    }
                } else if monoB[i] == "백" {
                    if monoB[i-1].count == 1 && monoB[i-1].first!.getCharacterForm() == .koreanNumeric {
                        monoB[i-1] = "\((Int(monoB[i-1].first!.getCorrespondingArabicString()) ?? 0) * 100)"
                        monoB.remove(at: i)
                    } else {
                        monoB[i] = "100"
                    }
                } else if monoB[i] == "천" {
                    if monoB[i-1].count == 1 && monoB[i-1].first!.getCharacterForm() == .koreanNumeric {
                        monoB[i-1] = "\((Int(monoB[i-1].first!.getCorrespondingArabicString()) ?? 0) * 1000)"
                        monoB.remove(at: i)
                    } else {
                        monoB[i] = "1000"
                    }
                }
            }
        }
        if monoB.count > 0 {
            if monoB[0] == "십" {
                monoB[0] = "10"
            } else if monoB[0] == "백" {
                monoA[0] = "100"
            } else if monoB[0] == "천" {
                monoB[0] = "1000"
            }
        }
        
        // 10. A, B, C에서 남은 한글 숫자는 숫자 그대로 아라비아로 바꾸기
        
        for i in 0..<monoA.count {
            if monoA[i].count == 1 && monoA[i].first!.getCharacterForm() == .koreanNumeric {
                monoA[i] = monoA[i].first!.getCorrespondingArabicString()
            }
        }
        
        for i in 0..<monoB.count {
            if monoB[i].count == 1 && monoB[i].first!.getCharacterForm() == .koreanNumeric {
                monoB[i] = monoB[i].first!.getCorrespondingArabicString()
            }
        }
        
        for i in 0..<monoC.count {
            if monoC[i].count == 1 && monoC[i].first!.getCharacterForm() == .koreanNumeric {
                monoC[i] = monoC[i].first!.getCorrespondingArabicString()
            }
        }
        
        // 11.  A, B 각각 안에 포함된 수 전부 덧셈하기: sumA: Int, sumB: Int
        
        var sumA = 0
        var sumB = 0
        for mono in monoA {
            sumA += Int(mono) ?? 0
        }
        for mono in monoB {
            sumB += Int(mono) ?? 0
        }
        
        // 12. C 앞에 "0." 더해주고 그것을 Double로 바꾸기: doubleC
        
        var reducedC = monoC.reduce("") { $0 + $1 }
        reducedC = "0." + reducedC
        let doubleC = Double(reducedC) ?? 0.0
        
        // 13. sum = Double(sumA * 10000) + Double(sumB) + doubleC
        
        sum = Double(sumA * 10000) + Double(sumB) + doubleC
        
        // 14. sum을 payAmount로 넘기기
        
        payAmount = sum
        
        // MARK: - splitArray에 남아 있는 나머지는 공백 생략하지 않은 문자열로 합친 후에 구매내역 퍼블리시드 변수에 입력
        
        info = splitArray.getUnifiedStringWithSpaceBetweenEachSplit()
    }
    
    func alterVoiceSentence() {
        if voiceSentenceChoicer < RecordViewModel.voiceSentenceArray.count - 1 {
            voiceSentenceChoicer += 1
        } else if voiceSentenceChoicer == RecordViewModel.voiceSentenceArray.count - 1 {
            voiceSentenceChoicer = 0
        }
        voiceSentence = RecordViewModel.voiceSentenceArray[voiceSentenceChoicer]
    }
}