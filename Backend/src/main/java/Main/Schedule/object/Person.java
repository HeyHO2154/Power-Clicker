package Main.Schedule.object;

public class Person {
    private long id;
    private String name;
    private int gender; // 0: 남성, 1: 여성
    private int age;
    private boolean married;
    private int race;
    
    private Dynasty dynasty;

    // 생성자
    public Person(long id, String name, int gender, int race, Dynasty dynasty) {
        this.id = id;
        this.name = name;
        this.gender = gender;
        this.age = 0;
        this.married = false;
        this.race = race;
        this.setDynasty(dynasty);
    }

    // Getter & Setter
    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getGender() {
        return gender;
    }

    public void setGender(int gender) {
        this.gender = gender;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public boolean isMarried() {
        return married;
    }

    public void setMarried(boolean married) {
        this.married = married;
    }

    public int getRace() {
        return race;
    }

    public void setRace(int race) {
        this.race = race;
    }

	public Dynasty getDynasty() {
		return dynasty;
	}

	public void setDynasty(Dynasty dynasty) {
		this.dynasty = dynasty;
	}
}
