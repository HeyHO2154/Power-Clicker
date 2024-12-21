package Main.Schedule.object;

public class Player {
    private long id;
    private String name;
    private boolean gender; // true: 남성, false: 여성
    private int age;
    private boolean married;
    private int race;

    // 생성자
    public Player(long id, String name, boolean gender, int race) {
        this.id = id;
        this.name = name;
        this.gender = gender;
        this.age = 0;
        this.married = false;
        this.race = race;
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

    public boolean isGender() {
        return gender;
    }

    public void setGender(boolean gender) {
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
}
