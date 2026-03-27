//
//  VisualLayoutCell.swift
//  AnchorageDemo
//

import UIKit
import Anchorage

class VisualLayoutCell: BaseCell {
    override class func reuseId() -> String {
        return "VisualLayoutCell"
    }

    let bodyLabel: UILabel = {
        let l = UILabel()
        l.text = "Visual Layout DSL: views stacked vertically using layout(in:). Top row uses |--view--| (zero margins), middle uses |--[a,b]--| (two equal-width views), bottom uses |view| (edge to edge)."
        l.font = UIFont.systemFont(ofSize: 12.0)
        l.numberOfLines = 0
        return l
    }()

    let topView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        return v
    }()

    let middleLeft: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGreen
        return v
    }()

    let middleRight: UIView = {
        let v = UIView()
        v.backgroundColor = .systemOrange
        return v
    }()

    let bottomView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemRed
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
        configureLayout()
    }
}

private extension VisualLayoutCell {
    func configureView() {
		
	}

    func configureLayout() {
			contentView.layout {
				8
				|--8--bodyLabel--8--|
				8
				|--8--UIView().layout({
					|--topView--| /=/ 30
					8
					|--15--[middleLeft,50,middleRight]--20--| /=/ 50
					8
					|bottomView| /=/ 50
				})--|
				8
			}
	    }
}
