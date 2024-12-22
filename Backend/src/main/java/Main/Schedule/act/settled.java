package Main.Schedule.act;

import java.util.ArrayList;
import java.util.List;

import Main.Schedule.GameData;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Person;
import Main.Schedule.object.Region;

public class settled {
	public static GameData act(GameData gamedata, int num) {
		Dynasty dynasty = gamedata.getDynasties().get(num);
		int act = (int) (Math.random()*3);
		switch (act) {
			case 0:
			case 1:
			default:
				System.out.print(dynasty.getLocation().getName()+"에 대기");
				break;
		}
		
		//만나면 결혼
		Person a = dynasty.getMember().get((int) (Math.random()*dynasty.getMember().size()));
		if(!a.isMarried()) {
			//현 위치에서 랜덤 가문 선택, 거기서 랜덤 인원 선택
			Dynasty B = dynasty.getLocation().getNomad().get((int) (Math.random()*dynasty.getLocation().getNomad().size()));
			Person b = B.getMember().get((int) (Math.random()*B.getMember().size()));
			if(!b.isMarried() && a.getGender()!=b.getGender() && B!=dynasty) {
				//결혼 조건이 맞으면 진행
				System.out.print("/ "+dynasty.getName()+"의 "+a.getName()+"와 "+B.getName()+"의 "+b.getName()+"가 결혼하였습니다. ");
				B.getMember().remove(b);
				if(B.getMember().size()==0) {
					System.out.print("/ "+B.getName()+"이 흡수됨");
					dynasty.getLocation().getNomad().remove(B);
					gamedata.getDynasties().remove(B);
				}
				dynasty.getMember().add(b);
				a.setMarried(true);
				b.setMarried(true);
				int rand = (int) (Math.random()*4)+1;
				for (int i = 0; i < rand; i++) {
					Person baby = new Person(gamedata.getId(), "이름"+(gamedata.getId()-1), (int) (Math.random()*2), 0);
					dynasty.getMember().add(baby);
					System.out.print("/ "+baby.getName()+"이 태어남");
				}
			}
		}
		
		//정착하기로 결심
		if((int) (Math.random()*10) == 1) {
			if(dynasty.getLocation().getOccupy().getId()==0) {
				//건국
				Faction newKingdom = new Faction(gamedata.getId(), dynasty.getName()+"의 왕국", 1);
				newKingdom.getOccupies().add(dynasty.getLocation());
				dynasty.getLocation().setOccupy(newKingdom);
				dynasty.getLocation().getNomad().remove(dynasty);
				dynasty.getLocation().getSettled().add(dynasty);
				dynasty.setFaction(newKingdom);
				gamedata.getFactions().add(newKingdom);
				System.out.print("/ "+newKingdom.getName()+"이 "+dynasty.getLocation().getName()+"에 건국되었습니다.");
			}else {
				//합류
				Faction Kingdom = dynasty.getLocation().getOccupy();
				dynasty.getLocation().getNomad().remove(dynasty);
				dynasty.getLocation().getSettled().add(dynasty);
				dynasty.setFaction(Kingdom);
				System.out.print("/ "+Kingdom.getName()+"에 "+dynasty.getLocation().getName()+"가 합류하였습니다.");
			}
		}
		
		
		System.out.println();
		return gamedata;
	}
}
