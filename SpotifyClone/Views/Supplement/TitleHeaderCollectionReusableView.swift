//
//  TitleHeaderCollectionReusableView.swift
//  SpotifyClone
//
//  Created by Sen Lin on 8/3/2022.
//

import UIKit

class TitleHeaderCollectionReusableView: UICollectionReusableView{
    
    static let identifier = "TitleHeaderCollectionReusableView"
    
    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(sectionLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sectionLabel.frame = CGRect(x: 15, y: 0, width: frame.width, height: frame.height)
    }
    
    func configure(with label: String){
        sectionLabel.text = label
    }

}
